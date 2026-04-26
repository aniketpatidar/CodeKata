require "test_helper"

class DuelTest < ActiveSupport::TestCase
  def setup
    @user1 = users(:one)
    @user2 = users(:two)
    @challenge = challenges(:one)
  end

  test "duel requires challenger, opponent, and challenge" do
    duel = Duel.new(status: 0)
    assert_not duel.valid?
    assert duel.errors.include?(:challenger_id)
    assert duel.errors.include?(:opponent_id)
    assert duel.errors.include?(:challenge_id)
  end

  test "duel cannot be between same user" do
    duel = Duel.new(
      challenger: @user1,
      opponent: @user1,
      challenge: @challenge
    )
    assert_not duel.valid?
    assert duel.errors.include?(:opponent_id)
  end

  test "participant? returns true for challenger and opponent" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge
    )
    assert duel.participant?(@user1)
    assert duel.participant?(@user2)
  end

  test "opponent_of returns correct opponent" do
    duel = Duel.create!(
      challenger: @user1,
      opponent: @user2,
      challenge: @challenge
    )
    assert_equal @user2, duel.opponent_of(@user1)
    assert_equal @user1, duel.opponent_of(@user2)
  end
end
