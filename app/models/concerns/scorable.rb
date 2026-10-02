module Scorable
  extend ActiveSupport::Concern

  included do
    SCORING_RULES = { "easy" => 10, "medium" => 20, "hard" => 30 }.freeze
    TIME_BONUS_RATE = 0.2
  end

  def score_for_challenges(solved_challenges, all_solved:, time_bonus_params: {})
    base = solved_challenges.sum { |ch| SCORING_RULES.fetch(ch.difficulty) }
    return base unless all_solved && time_bonus_params.any?
    base + calculate_time_bonus(base, time_bonus_params)
  end

  private

  def calculate_time_bonus(base, params)
    deadline = params[:deadline_at]
    finished = params[:finished_at]
    duration = params[:duration]
    (base * TIME_BONUS_RATE * (deadline - finished) / duration.to_f).round
  end
end
