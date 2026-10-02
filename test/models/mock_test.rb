require "test_helper"

class MockTest < ActiveSupport::TestCase
  include MockHelpers

  setup do
    travel_to Time.zone.local(2026, 9, 30, 10, 0, 0)
    @user = users(:one)
  end

  test "rejects unknown paper keys" do
    mock = Mock.new(user: @user, paper_key: "nope", started_at: Time.current, deadline_at: 1.hour.from_now)
    assert_not mock.valid?
    assert_includes mock.errors[:paper_key], "is not included in the list"
  end

  test "paper returns the MockPaper" do
    mock = build_mock!(user: @user, challenges: create_challenges!(:easy, 3))
    assert_equal "Sprint", mock.paper.name
  end

  test "mock_challenges are ordered by position" do
    challenges = create_challenges!(:easy, 3)
    mock = build_mock!(user: @user, challenges: challenges)
    assert_equal [1, 2, 3], mock.mock_challenges.map(&:position)
  end

  test "database allows only one in-progress mock per user" do
    build_mock!(user: @user, challenges: create_challenges!(:easy, 3))
    assert_raises(ActiveRecord::RecordNotUnique) do
      Mock.create!(user: @user, paper_key: "sprint", started_at: Time.current, deadline_at: 20.minutes.from_now)
    end
  end

  test "MockChallenge#starting_code falls back to the template with real newlines" do
    mock = build_mock!(user: @user, challenges: create_challenges!(:easy, 3))
    mock_challenge = mock.mock_challenges.first
    assert_equal "def solve(x)\n  \nend", mock_challenge.starting_code

    mock_challenge.update!(code: "def solve(x) = x")
    assert_equal "def solve(x) = x", mock_challenge.starting_code
  end

  def standard_mock
    easy   = create_challenges!(:easy, 2)
    medium = create_challenges!(:medium, 2)
    build_mock!(user: @user, challenges: easy + medium, paper_key: "standard")
  end

  test "start! creates an in-progress mock with deadline and challenges per the paper mix" do
    create_challenges!(:easy, 2)
    create_challenges!(:medium, 2)

    mock = Mock.start!(user: @user, paper: MockPaper.find("standard"))

    assert mock.in_progress?
    assert_equal Time.current, mock.started_at
    assert_equal 45.minutes.from_now, mock.deadline_at
    assert_equal [1, 2, 3, 4], mock.mock_challenges.map(&:position)
    assert_equal %w[easy easy medium medium], mock.mock_challenges.map { |mc| mc.challenge.difficulty }.sort
  end

  test "start! prefers challenges the user has not solved" do
    solved = challenges(:one)
    ChallengeCompletion.create!(user: @user, challenge: solved)
    unsolved = create_challenges!(:easy, 3)

    mock = Mock.start!(user: @user, paper: MockPaper.find("sprint"))

    assert_equal unsolved.map(&:id).sort, mock.challenges.map(&:id).sort
  end

  test "start! falls back to solved challenges when unsolved run out" do
    extra = create_challenges!(:easy, 2)
    ChallengeCompletion.create!(user: @user, challenge: extra.first)
    ChallengeCompletion.create!(user: @user, challenge: extra.last)
    # easy pool: fixture one (unsolved) + 2 solved extras

    mock = Mock.start!(user: @user, paper: MockPaper.find("sprint"))

    assert_equal 3, mock.challenges.size
    assert_includes mock.challenges, challenges(:one)
  end

  test "start! raises NotEnoughChallenges and creates nothing when the pool is too small" do
    # only one easy challenge exists (fixture)
    assert_no_difference ["Mock.count", "MockChallenge.count"] do
      assert_raises(Mock::NotEnoughChallenges) do
        Mock.start!(user: @user, paper: MockPaper.find("sprint"))
      end
    end
  end

  def solve!(mock, *positions)
    mock.mock_challenges.where(position: positions).update_all(solved_at: Time.current)
  end

  test "finish! scores solved challenges by difficulty without bonus when some are unsolved" do
    mock = standard_mock
    solve!(mock, 1, 3) # one easy, one medium

    travel 10.minutes
    mock.finish!

    assert mock.finished?
    assert_equal Time.current, mock.finished_at
    assert_equal 30, mock.score
  end

  test "finish! adds the time bonus when every challenge is solved" do
    mock = standard_mock
    solve!(mock, 1, 2, 3, 4)

    travel 30.minutes # 15 of 45 minutes left
    mock.finish!

    assert_equal 64, mock.score # 60 + round(60 * 0.2 * 15/45)
  end

  test "finish! caps finished_at at the deadline" do
    mock = standard_mock
    travel 50.minutes
    mock.finish!

    assert_equal mock.deadline_at, mock.finished_at
  end

  test "finish! is a no-op on a finished mock" do
    mock = standard_mock
    travel 5.minutes
    mock.finish!
    travel 5.minutes

    assert_no_changes -> { mock.reload.finished_at } do
      mock.finish!
    end
  end

  test "finish_if_expired! leaves a mock alone before the deadline and finishes it after" do
    mock = standard_mock

    travel 44.minutes
    assert mock.finish_if_expired!.in_progress?

    travel 1.minute
    assert mock.finish_if_expired!.finished?
    assert_equal mock.deadline_at, mock.finished_at
  end

  test "personal_best? compares against the user's other finished mocks on the same paper" do
    first = standard_mock
    solve!(first, 1)
    first.finish! # score 10
    assert first.personal_best?

    second = standard_mock
    solve!(second, 1)
    second.finish! # score 10, ties are not a new best
    assert_not second.personal_best?

    third = standard_mock
    solve!(third, 1, 3)
    third.finish! # score 30
    assert third.personal_best?
  end

  test "record_solve! stamps solved_at and keeps the mock running while others are unsolved" do
    mock = standard_mock
    mock_challenge = mock.mock_challenges.first

    mock.record_solve!(mock_challenge, at: Time.current)

    assert_equal Time.current, mock_challenge.reload.solved_at
    assert mock.reload.in_progress?
  end

  test "record_solve! on the last challenge finishes the mock at the solve time with bonus" do
    mock = standard_mock
    solve!(mock, 1, 2, 3)

    travel 30.minutes # 15 of 45 minutes left
    mock.record_solve!(mock.mock_challenges.last, at: Time.current)

    mock.reload
    assert mock.finished?
    assert_equal Time.current, mock.finished_at
    assert_equal 64, mock.score
  end

  test "record_solve! on a mock finished mid-evaluation records the solve and rescores" do
    mock = standard_mock
    received_at = 44.minutes.from_now
    travel 46.minutes
    mock.finish_if_expired! # timer finished it while Judge0 was running

    mock.record_solve!(mock.mock_challenges.first, at: received_at)

    mock.reload
    assert mock.finished?
    assert_equal 10, mock.score
    assert_equal received_at, mock.mock_challenges.first.solved_at
  end

  test "record_solve! does not overwrite an earlier solve" do
    mock = standard_mock
    mock_challenge = mock.mock_challenges.first
    first_time = Time.current
    mock.record_solve!(mock_challenge, at: first_time)

    travel 5.minutes
    mock.record_solve!(mock_challenge, at: Time.current)

    assert_equal first_time, mock_challenge.reload.solved_at
  end
end
