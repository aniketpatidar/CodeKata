module Mocks
  class ChallengesController < ApplicationController
    include MockScoped

    def update
      @mock_challenge.update!(code: params.fetch(:code).to_s)
      head :no_content
    end
  end
end
