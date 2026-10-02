module Mocks
  class SubmissionsController < ApplicationController
    include MockScoped

    def create
      @mock_challenge.update!(code: params.fetch(:code).to_s)
      result = CodeEvaluation.run(user: current_user, challenge: @mock_challenge.challenge, code: @mock_challenge.code)
      @mock.record_solve!(@mock_challenge, at: @received_at) if result.all_passed?
      render json: submission_response(result)
    rescue KeyError
      render json: { error: "JUDGE0_API_KEY is not configured." }, status: :service_unavailable
    rescue => e
      Rails.logger.error("Mock submission failed: #{e.message}")
      render json: { error: "Code evaluation failed. Please try again." }, status: :internal_server_error
    end

    private

    def submission_response(result)
      @mock.reload
      {
        output: result.test_results,
        solved: @mock_challenge.reload.solved?,
        solved_count: @mock.solved_count,
        total: @mock.mock_challenges.size,
        finished: @mock.finished?,
        results_url: mock_path(@mock)
      }
    end
  end
end
