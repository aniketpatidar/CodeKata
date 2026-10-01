require "test_helper"

class Mocks::ChallengesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include MockHelpers

  setup do
    travel_to Time.zone.local(2026, 9, 30, 10, 0, 0)
    sign_in users(:one)
    @mock = build_mock!(user: users(:one), challenges: create_challenges!(:easy, 3))
  end

  test "update autosaves code for the position" do
    patch mock_challenge_path(@mock, 2), params: { code: "def solve(x) = x" }, as: :json

    assert_response :no_content
    assert_equal "def solve(x) = x", @mock.mock_challenges.find_by(position: 2).code
  end

  test "update accepts empty code" do
    patch mock_challenge_path(@mock, 1), params: { code: "" }, as: :json
    assert_response :no_content
  end

  test "update after the deadline returns 409 and saves nothing" do
    travel 21.minutes

    patch mock_challenge_path(@mock, 1), params: { code: "late" }, as: :json

    assert_response :conflict
    assert_equal true, response.parsed_body["finished"]
    assert_equal mock_path(@mock), response.parsed_body["results_url"]
    assert_nil @mock.mock_challenges.find_by(position: 1).code
    assert @mock.reload.finished?
  end

  test "update on another user's mock returns 404" do
    other = build_mock!(user: users(:two), challenges: create_challenges!(:easy, 3))
    patch mock_challenge_path(other, 1), params: { code: "x" }, as: :json
    assert_response :not_found
  end
end
