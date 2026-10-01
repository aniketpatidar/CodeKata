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

  test "profile shows 'Connected' badge when viewing a friend's profile" do
    get user_path(users(:two))
    assert_response :success
    assert_select ".ck-chip--completed", text: /Connected/
    assert_select "button[type=submit]", text: "Send Friend Invitation", count: 0
  end

  test "profile shows 'Send Friend Invitation' button when viewing a non-friend's profile" do
    get user_path(users(:three))
    assert_response :success
    assert_select "button[type=submit]", text: "Send Friend Invitation"
  end

  test "profile shows 'Invitation Sent' when viewing a profile the user has invited" do
    users(:one).send_invitation(users(:three))
    get user_path(users(:three))
    assert_response :success
    assert_select "button.ck-btn-outline", text: "Invitation Sent"
    assert_select "button[type=submit]", text: "Send Friend Invitation", count: 0
  end

  test "profile shows 'Invitation Pending' when viewing a profile that invited the user" do
    users(:three).send_invitation(users(:one))
    get user_path(users(:three))
    assert_response :success
    assert_select "button.ck-btn-outline", text: "Invitation Pending"
    assert_select "button[type=submit]", text: "Send Friend Invitation", count: 0
  end
end
