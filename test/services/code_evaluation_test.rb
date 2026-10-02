require "test_helper"

class CodeEvaluationTest < ActiveSupport::TestCase
  include MockHelpers

  def setup
    @user = users(:one)
    @challenge = create_challenges!(:easy, 1).first
  end

  def teardown
    CodeEvaluation.executor = nil
  end

  test "uses the class-level executor by default" do
    fake_executor = FakeCodeExecutor.new(all_pass: true)
    CodeEvaluation.executor = fake_executor

    result = CodeEvaluation.run(user: @user, challenge: @challenge, code: "def solve(x); x; end")

    assert result.all_passed?
    assert ChallengeCompletion.exists?(user: @user, challenge: @challenge)
  end

  test "defaults to Judge0Service when no executor is set" do
    CodeEvaluation.executor = nil

    executor = CodeEvaluation.executor

    assert_instance_of Judge0Service, executor
  end
end
