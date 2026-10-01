# Rejects writes once the mock is over — this is where the hard stop lives.
module MockScoped
  extend ActiveSupport::Concern

  included do
    before_action :note_received_at, :set_mock, :set_mock_challenge, :require_mock_in_progress
  end

  private

  def note_received_at
    @received_at = Time.current
  end

  def set_mock
    @mock = current_user.mocks.find(params[:mock_id])
  end

  def set_mock_challenge
    @mock_challenge = @mock.mock_challenges.find_by!(position: params[:position])
  end

  def require_mock_in_progress
    return if @mock.finish_if_expired!(@received_at).in_progress?

    render json: { finished: true, results_url: mock_path(@mock) }, status: :conflict
  end
end
