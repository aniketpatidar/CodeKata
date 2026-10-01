require "application_system_test_case"

class MocksTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include MockHelpers

  setup do
    @user = users(:one)
    mark_existing_challenges_solved!(@user) # keep fixture challenges (unparseable tests) out of the mock
    create_challenges!(:easy, 3)
    CodeEvaluation.executor = FakeCodeExecutor.new(all_pass: true)
    sign_in @user
  end

  teardown { CodeEvaluation.executor = nil }

  test "start a Sprint, solve every challenge, see results" do
    visit mocks_path
    click_button "Start", match: :first # Sprint is the first paper

    assert_selector "[data-mock-target=clock]", text: /\A(20:00|19:5\d)\z/
    mock = @user.mocks.last

    (1..3).each do |position|
      visit mock_path(mock, position: position)
      click_button "Submit"
      assert_text(/passed: ✅/i) unless position == 3
    end

    assert_text(/results/i)
    assert_text(/3\/3/)
    assert_text(/new personal best/i)
    assert mock.reload.finished?
  end
end
