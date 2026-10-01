require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:one)
  end

  test "dashboard links to timed mocks" do
    get home_path
    assert_select "a[href=?]", mocks_path
  end

  test "should get index" do
    get home_url
    assert_response :success
  end

  test "home shows featured challenges" do
    get home_url
    assert_select ".ck-card", minimum: 1
  end

  test "home shows timed mocks section" do
    get home_url
    assert_select ".ck-meta", text: /Timed mocks/i
  end

end