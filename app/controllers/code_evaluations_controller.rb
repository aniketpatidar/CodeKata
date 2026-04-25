class CodeEvaluationsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def evaluate
    challenge = Challenge.find(params[:id])
    results = Judge0Service.new.run_tests(params[:code], challenge.tests, challenge.method_name)

    all_passed = results.values.all? { |r| r[:passed] }
    ChallengeCompletion.find_or_create_by(user: current_user, challenge: challenge) if all_passed

    broadcast_duel_progress(params[:duel_id], results) if params[:duel_id].present?

    render json: { output: results }
  rescue KeyError
    render json: { error: "JUDGE0_API_KEY is not configured." }, status: :service_unavailable
  rescue => e
    Rails.logger.error("Code evaluation failed")
    render json: { error: "Code evaluation failed. Please try again." }, status: :internal_server_error
  end

  private

  def broadcast_duel_progress(duel_id, results)
    duel = Duel.find_by(id: duel_id)
    return unless duel&.active? && duel.participant?(current_user)

    passed = results.values.count { |r| r[:passed] }
    total  = results.values.size

    ActionCable.server.broadcast("duel_#{duel.id}", {
      type: "progress",
      user_id: current_user.id,
      passed: passed,
      total: total
    })

    return unless passed == total

    # Atomic update — only the first player to pass claims the win
    rows = Duel.where(id: duel.id, status: :active)
               .update_all(status: :completed, winner_id: current_user.id, completed_at: Time.current)
    return unless rows == 1

    ActionCable.server.broadcast("duel_#{duel.id}", {
      type: "duel_won",
      winner_id: current_user.id,
      winner_name: current_user.full_name
    })
  end
end
