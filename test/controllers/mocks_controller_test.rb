require "test_helper"

class MocksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include MockHelpers

  setup do
    sign_in users(:one)
    travel_to Time.zone.parse("2026-09-30 10:00:00")
    create_challenges!(:easy, 5)
    create_challenges!(:medium, 5)
    create_challenges!(:hard, 5)
  end

  teardown do
    travel_back
  end

  test "index lists all papers" do
    get mocks_path
    assert_response :success
    assert_includes @response.body, "Sprint"
    assert_includes @response.body, "Standard"
    assert_includes @response.body, "Marathon"
  end

  test "index shows resume banner and countdown for in-progress mock" do
    mock = build_mock!(user: users(:one), challenges: Challenge.limit(3), paper_key: "sprint")

    get mocks_path
    assert_response :success
    assert_includes @response.body, "Resume"
    assert_includes @response.body, "Sprint"
  end

  test "create starts mock and redirects to show with created mock_challenges" do
    assert_difference ["Mock.count"], 1 do
      assert_difference ["MockChallenge.count"], 3 do
        post mocks_path, params: { paper: "sprint" }
      end
    end

    mock = Mock.last
    assert_redirected_to mock_path(mock)
    assert_equal users(:one), mock.user
    assert_equal "sprint", mock.paper_key
    assert_equal 3, mock.mock_challenges.size
  end

  test "create redirects to existing in-progress mock instead of starting new" do
    mock1 = build_mock!(user: users(:one), challenges: Challenge.limit(3), paper_key: "sprint")

    assert_no_difference "Mock.count" do
      post mocks_path, params: { paper: "standard" }
    end

    assert_redirected_to mock_path(mock1)
  end

  test "create rejects unknown paper with alert" do
    assert_no_difference "Mock.count" do
      post mocks_path, params: { paper: "unknown" }
    end

    assert_redirected_to mocks_path
    assert_equal "Unknown paper.", flash[:alert]
  end

  test "create explains not enough challenges" do
    mark_existing_challenges_solved!(users(:one))
    Challenge.where(difficulty: "medium").destroy_all

    assert_no_difference "Mock.count" do
      post mocks_path, params: { paper: "marathon" }
    end

    assert_redirected_to mocks_path
    assert_includes flash[:alert], "Not enough challenges for Marathon yet."
  end

  test "show after deadline finishes mock and renders results" do
    mock = build_mock!(user: users(:one), challenges: Challenge.limit(3), paper_key: "sprint", started_at: 1.hour.ago)

    get mock_path(mock)

    mock.reload
    assert mock.finished?
    assert_response :success
    assert_select "h1", text: mock.paper.name
  end

  test "show returns 404 for another user's mock" do
    mock = build_mock!(user: users(:two), challenges: Challenge.limit(3), paper_key: "sprint")

    get mock_path(mock)

    assert_response :not_found
  end

  test "finish ends mock early and redirects to results" do
    mock = build_mock!(user: users(:one), challenges: Challenge.limit(3), paper_key: "sprint")

    post finish_mock_path(mock)

    mock.reload
    assert mock.finished?
    assert_redirected_to mock_path(mock)
  end

  test "show renders the exam with the first challenge, countdown and finish button" do
    challenges = create_challenges!(:easy, 3)
    mock = build_mock!(user: users(:one), challenges: challenges)
    travel 5.minutes

    get mock_path(mock)

    assert_response :success
    assert_match challenges.first.name, response.body
    assert_match "15:00", response.body
    assert_match "Finish now", response.body
    assert_select "[data-controller=mock]"
    assert_select "[data-mock-save-url-value=?]", mock_challenge_path(mock, 1)
    assert_select "textarea[data-mock-target=editor]", text: "def solve(x)\n  \nend"
  end

  test "show selects the challenge from the position param" do
    challenges = create_challenges!(:easy, 3)
    mock = build_mock!(user: users(:one), challenges: challenges)

    get mock_path(mock, position: 2)

    assert_match challenges.second.name, response.body
    assert_select "[data-mock-save-url-value=?]", mock_challenge_path(mock, 2)
  end

  test "show restores autosaved code" do
    mock = build_mock!(user: users(:one), challenges: create_challenges!(:easy, 3))
    mock.mock_challenges.first.update!(code: "def solve(x) = x")

    get mock_path(mock)

    assert_select "textarea[data-mock-target=editor]", text: "def solve(x) = x"
  end
end
