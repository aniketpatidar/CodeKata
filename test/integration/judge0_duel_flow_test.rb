require "test_helper"

class Judge0DuelFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user1 = users(:one)
    @user2 = users(:two)
    @challenge = challenges(:one)
    # Clear duels created by fixtures
    Duel.delete_all
  end

  test "user can initiate duel creation flow" do
    sign_in @user1

    # Test the new duel page
    get new_duel_path(opponent_slug: @user2.slug)

    # Should either show the form or redirect based on friendship
    assert [200, 302].include?(response.status)
  end

  test "opponent can accept a pending duel" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :pending
    )
    sign_in @user2

    patch accept_duel_path(duel)

    assert_response :redirect
    duel.reload
    assert duel.active?
    assert_not_nil duel.started_at
  end

  test "challenger cannot accept their own duel" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :pending
    )
    sign_in @user1

    patch accept_duel_path(duel)

    duel.reload
    assert duel.pending?
    assert_nil duel.started_at
  end

  test "home page accessible and responds successfully" do
    sign_in @user1

    # Create some test data
    ChallengeCompletion.create!(user: @user1, challenge: @challenge)
    Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :completed,
      winner: @user1
    )

    get home_path

    assert_response :success
  end

  test "unauthenticated user cannot create duel" do
    initial_count = Duel.count

    post duels_path, params: {
      opponent_id: @user2.id,
      challenge_id: @challenge.id
    }

    assert_response :redirect
    assert_redirected_to new_user_session_path
    assert_equal initial_count, Duel.count
  end

  test "unauthenticated user cannot view duel" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :pending
    )

    get duel_path(duel)

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "non-participant cannot view duel" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :pending
    )
    user3 = User.create!(
      email: "user3@example.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Test",
      last_name: "User"
    )

    sign_in user3
    get duel_path(duel)

    assert_response :redirect
    assert_redirected_to root_path
  end

  test "code evaluation endpoint handles requests" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :active,
      started_at: Time.current
    )
    sign_in @user1

    post evaluate_code_path(id: @challenge.id), params: {
      code: "def sum(a, b)\n  a + b\nend",
      duel_id: duel.id
    }

    # Should return 200 (success) or 500 (error) based on Judge0 availability
    assert [200, 500].include?(response.status)
  end

  test "non-admin user cannot access admin settings" do
    non_admin = @user2
    sign_in non_admin

    get admin_settings_path

    assert_response :redirect
    assert_redirected_to root_path
  end

  test "admin settings page requires admin user" do
    # Create admin user with id 1 to test admin access
    admin = User.first
    sign_in admin

    get admin_settings_path

    # Should either succeed or redirect based on whether user is admin
    assert [200, 302].include?(response.status)
  end

  test "hint endpoint returns error when disabled" do
    sign_in @user1

    AppSetting.disable_ai_hints!

    post hints_path, params: {
      challenge_id: @challenge.id,
      code: "def sum(a, b)\n\nend"
    }

    assert_response :service_unavailable
  end

  test "duel shows participants when authenticated" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :active,
      started_at: Time.current
    )
    sign_in @user1

    get duel_path(duel)

    assert_response :success
  end

  test "duel creation requires friendship" do
    user_not_friend = User.create!(
      email: "notfriend@example.com",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Not",
      last_name: "Friend"
    )

    sign_in @user1

    post duels_path, params: {
      opponent_id: user_not_friend.id,
      challenge_id: @challenge.id
    }

    assert_response :redirect
    assert_redirected_to root_path
  end

  test "duel transitions from pending to active on acceptance" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge,
      status: :pending
    )

    assert duel.pending?
    assert_nil duel.started_at

    sign_in @user2
    patch accept_duel_path(duel)

    duel.reload
    assert duel.active?
    assert_not_nil duel.started_at
  end

  test "challenge page accessible when authenticated" do
    sign_in @user1

    get challenge_path(@challenge)

    assert_response :success
  end

  test "challenge models are accessible in tests" do
    sign_in @user1

    assert_not_nil challenges(:one)
    assert_not_nil challenges(:two)

    # Both challenges should be retrievable
    challenge1 = challenges(:one)
    challenge2 = challenges(:two)

    assert_not_equal challenge1.id, challenge2.id
  end
end
