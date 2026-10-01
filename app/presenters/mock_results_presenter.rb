class MockResultsPresenter
  def initialize(mock, mock_challenges)
    @mock = mock
    @mock_challenges = mock_challenges
  end

  def score = @mock.score
  def solved_count = @mock.solved_count
  def total_count = @mock_challenges.size
  def time_taken = @mock.time_taken
  def is_personal_best? = @mock.personal_best?
  def challenges = @mock_challenges

  def score_label
    "#{solved_count}/#{total_count}"
  end

  def personal_best_badge
    return nil unless is_personal_best?
    "New personal best!"
  end
end
