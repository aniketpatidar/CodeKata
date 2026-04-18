class HintsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def create
    unless AppSetting.ai_hints_enabled?
      return render json: { error: "AI hints are currently disabled." }, status: :service_unavailable
    end

    challenge = Challenge.find(params[:challenge_id])
    hint = GeminiService.new.hint(challenge.description, params[:code])
    render json: { hint: hint }
  rescue RubyLLM::AuthenticationError
    render json: { error: "GEMINI_API_KEY is not configured or invalid." }, status: :service_unavailable
  rescue => e
    Rails.logger.error("Hint failed: #{e.message}")
    render json: { error: "Could not generate a hint. Please try again." }, status: :internal_server_error
  end
end
