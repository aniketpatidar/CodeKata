class MocksController < ApplicationController
  before_action :set_mock, only: %i[show finish]

  def index
    @papers = MockPaper.all
    @current_mock = current_user.mocks.current
    @best_scores = current_user.mocks.finished.group(:paper_key).maximum(:score)
    @past_mocks = current_user.mocks.finished.order(started_at: :desc).limit(20)
  end

  def create
    return redirect_to_existing_mock if current_user.mocks.current
    paper = find_paper(params[:paper])
    return redirect_to_invalid_paper unless paper
    start_mock(paper)
  end

  def show
    @mock.finish_if_expired!
    @mock_challenges = @mock.mock_challenges.includes(:challenge).to_a
    @active = find_active_challenge || @mock_challenges.first
    render_results_or_exam
  end

  def finish
    @mock.finish!
    redirect_to mock_path(@mock)
  end

  private

  def set_mock
    @mock = current_user.mocks.find(params[:id])
  end

  def redirect_to_existing_mock
    redirect_to mock_path(current_user.mocks.current)
  end

  def find_paper(key)
    MockPaper.find(key)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def redirect_to_invalid_paper
    redirect_to mocks_path, alert: "Unknown paper."
  end

  def start_mock(paper)
    @mock = Mock.start!(user: current_user, paper: paper)
    redirect_to mock_path(@mock)
  rescue Mock::NotEnoughChallenges
    redirect_to mocks_path, alert: "Not enough challenges for #{paper.name} yet."
  rescue ActiveRecord::RecordNotUnique
    redirect_to mock_path(current_user.mocks.in_progress.first)
  end

  def find_active_challenge
    position = params[:position].to_i
    @mock_challenges.find { |mc| mc.position == position }
  end

  def render_results_or_exam
    if @mock.finished?
      @results = MockResultsPresenter.new(@mock, @mock_challenges)
      render :results
    end
  end
end
