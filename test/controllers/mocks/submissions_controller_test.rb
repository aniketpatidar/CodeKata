require "test_helper"

class Mocks::SubmissionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include MockHelpers

  # Simulates the client timer finishing the mock while Judge0 is still running.
  class FinishingExecutor < FakeCodeExecutor
    def initialize(mock_id)
      super(all_pass: true)
      @mock_id = mock_id
    end

    def run_tests(*)
      Mock.find(@mock_id).finish!(at: Mock.find(@mock_id).deadline_at)
      super
    end
  end

  class MissingKeyExecutor
    def run_tests(*) = raise(KeyError, "JUDGE0_API_KEY is not set")
  end

  setup do
    travel_to Time.zone.local(2026, 9, 30, 10, 0, 0)
    sign_in users(:one)
    @mock = build_mock!(user: users(:one), challenges: create_challenges!(:easy, 3))
    CodeEvaluation.executor = FakeCodeExecutor.new(all_pass: true)
  end

  teardown { CodeEvaluation.executor = nil }

  def submit(position: 1, code: "def solve(x) = x", mock: @mock)
    post mock_submissions_path(mock), params: { position: position, code: code }, as: :json
  end

  test "a passing submission records the solve at request time and saves the code" do
    submit

    assert_response :success
    body = response.parsed_body
    assert_equal true, body["solved"]
    assert_equal 1, body["solved_count"]
    assert_equal 3, body["total"]
    assert_equal false, body["finished"]
    assert body["output"].values.all? { |result| result["passed"] }

    mock_challenge = @mock.mock_challenges.find_by(position: 1)
    assert_equal Time.current, mock_challenge.solved_at
    assert_equal "def solve(x) = x", mock_challenge.code
  end

  test "a failing submission records nothing" do
    CodeEvaluation.executor = FakeCodeExecutor.new(all_pass: false)

    submit

    assert_response :success
    assert_equal false, response.parsed_body["solved"]
    assert_nil @mock.mock_challenges.find_by(position: 1).solved_at
  end

  test "a submission after the deadline returns 409 and records nothing" do
    travel 21.minutes

    submit

    assert_response :conflict
    assert_equal true, response.parsed_body["finished"]
    assert_nil @mock.mock_challenges.find_by(position: 1).solved_at
    assert @mock.reload.finished?
  end

  test "a solve received before the deadline counts even if the mock finished during evaluation" do
    CodeEvaluation.executor = FinishingExecutor.new(@mock.id)

    submit

    assert_response :success
    assert_equal true, response.parsed_body["finished"]
    @mock.reload
    assert_equal 10, @mock.score
    assert_equal Time.current, @mock.mock_challenges.find_by(position: 1).solved_at
  end

  test "solving the last challenge finishes the mock" do
    @mock.mock_challenges.where(position: [1, 2]).update_all(solved_at: Time.current)

    submit(position: 3)

    body = response.parsed_body
    assert_equal true, body["finished"]
    assert_equal mock_path(@mock), body["results_url"]
    assert @mock.reload.finished?
  end

  test "a missing Judge0 key returns 503" do
    CodeEvaluation.executor = MissingKeyExecutor.new

    submit

    assert_response :service_unavailable
    assert_equal "JUDGE0_API_KEY is not configured.", response.parsed_body["error"]
  end

  test "another user's mock returns 404" do
    other = build_mock!(user: users(:two), challenges: create_challenges!(:easy, 3))
    submit(mock: other)
    assert_response :not_found
  end
end
