class CodeEvaluation
  Result = Data.define(:test_results, :all_passed, :completion) do
    def all_passed? = all_passed
  end

  class << self
    attr_writer :executor

    def executor = @executor || Judge0Service.new
  end

  def self.run(user:, challenge:, code:, broadcaster: ActionCable.server, executor: self.executor)
    new(user:, challenge:, code:, broadcaster:, executor:).run
  end

  def initialize(user:, challenge:, code:, broadcaster:, executor:)
    @user        = user
    @challenge   = challenge
    @code        = code
    @broadcaster = broadcaster
    @executor    = executor
  end

  def run
    test_results = @executor.run_tests(@code, @challenge.parsed_tests, @challenge.method_template)
    all_passed   = test_results.values.all? { |r| r[:passed] }
    completion   = ChallengeCompletion.find_or_create_by(user: @user, challenge: @challenge) if all_passed

    Result.new(
      test_results:,
      all_passed:,
      completion:
    )
  end
end
