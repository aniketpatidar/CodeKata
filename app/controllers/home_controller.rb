class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    @active_duels = Duel.where(
      "(challenger_id = :id OR opponent_id = :id) AND status = :status",
      id: current_user.id, status: Duel.statuses[:active]
    ).includes(:challenge, :challenger, :opponent).order(started_at: :desc)

    @pending_duels = Duel.where(
      "(challenger_id = :id OR opponent_id = :id) AND status = :status",
      id: current_user.id, status: Duel.statuses[:pending]
    ).includes(:challenge, :challenger, :opponent).order(created_at: :desc)

    @duels_won  = Duel.where(winner_id: current_user.id).count
    @duels_played = Duel.where(
      "(challenger_id = :id OR opponent_id = :id) AND status = :status",
      id: current_user.id, status: Duel.statuses[:completed]
    ).count

    @challenges_solved = current_user.challenge_completions.count
    @friends = current_user.friends
    @featured_challenges = Challenge.order(:difficulty).limit(3)

    @new_user = @friends.empty? && @duels_played.zero? && @challenges_solved.zero?
  end
end
