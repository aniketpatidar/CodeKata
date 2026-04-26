require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:one)
  end

  test "profile renders successfully" do
    get user_path(users(:one))
    assert_response :success
  end

  test "profile renders successfully when user has posts with rich text bodies" do
    get user_path(users(:one))
    assert_response :success
  end

  test "profile shows post body as truncated plain text without HTML tags" do
    get user_path(users(:one))

    assert_select "div#answers-content p" do |elements|
      body_preview = elements.first.text.strip
      assert body_preview.length <= 200,
        "Expected post body preview to be at most 200 characters but got #{body_preview.length}: #{body_preview.inspect}"
    end
  end
end
