class DuelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_duel, only: %i[show accept]

  def new
    @opponent = User.find_by!(slug: params[:opponent_slug])
    return redirect_to root_path, alert: "You can only duel friends." unless current_user.friend_with?(@opponent)
    @challenges = Challenge.order(:difficulty, :name)
  end

  def create
    @opponent = User.find(params[:opponent_id])
    return redirect_to root_path, alert: "You can only duel friends." unless current_user.friend_with?(@opponent)

    @challenge = Challenge.find(params[:challenge_id])
    @duel = Duel.create!(
      challenger: current_user,
      opponent: @opponent,
      challenge: @challenge
    )

    redirect_to duel_path(@duel), notice: "Duel sent! Waiting for #{@opponent.first_name} to accept."
  end

  def show
    redirect_to root_path unless @duel.participant?(current_user)
  end

  def accept
    unless @duel.opponent == current_user && @duel.pending?
      return redirect_to duel_path(@duel)
    end

    @duel.update!(status: :active, started_at: Time.current)
    ActionCable.server.broadcast("duel_#{@duel.id}", { type: "duel_started" })
    redirect_to duel_path(@duel)
  end

  private

  def set_duel
    @duel = Duel.find(params[:id])
  end
end
