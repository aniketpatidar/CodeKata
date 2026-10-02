class Mock < ApplicationRecord
  include Scorable

  class NotEnoughChallenges < StandardError; end

  belongs_to :user
  has_many :mock_challenges, -> { order(:position) }, dependent: :destroy, inverse_of: :mock
  has_many :challenges, through: :mock_challenges

  enum :status, { in_progress: 0, finished: 1 }

  scope :in_progress, -> { where(status: :in_progress) }
  scope :finished, -> { where(status: :finished) }

  validates :paper_key, inclusion: { in: MockPaper.all.map(&:key) }
  validates :started_at, :deadline_at, presence: true

  def paper = MockPaper.find(paper_key)

  def self.start!(user:, paper:, now: Time.current)
    picked = ChallengeSelector.new(user, paper).call

    transaction do
      mock = create!(user: user, paper_key: paper.key, started_at: now, deadline_at: now + paper.duration)
      picked.each.with_index(1) { |challenge, position| mock.mock_challenges.create!(challenge: challenge, position: position) }
      mock
    end
  end

  def self.current
    mock = in_progress.first
    mock unless mock.nil? || mock.finish_if_expired!.finished?
  end

  def finish!(at: Time.current)
    with_lock { close(at) if in_progress? }
    self
  end

  def finish_if_expired!(now = Time.current)
    finish!(at: now) if in_progress? && now >= deadline_at
    self
  end

  def solved_count = mock_challenges.where.not(solved_at: nil).count

  def all_solved? = mock_challenges.where(solved_at: nil).none?

  def seconds_left(now = Time.current) = [(deadline_at - now).ceil, 0].max

  def time_taken = finished_at - started_at

  def personal_best?
    return false unless finished? && score.positive?

    previous_best = user.mocks.finished.where(paper_key: paper_key).where.not(id: id).maximum(:score)
    previous_best.nil? || score > previous_best
  end

  # `at` is when the submission request arrived, not when Judge0 answered.
  def record_solve!(mock_challenge, at:)
    with_lock do
      return if mock_challenge.reload.solved?
      mock_challenge.update!(solved_at: at)
      handle_solve_completion(at)
    end
  end

  private

  def close(at)
    self.status = :finished
    self.finished_at = [at, deadline_at].min
    self.score = calculated_score
    save!
  end

  def fetch_solved_challenges
    mock_challenges.includes(:challenge).where.not(solved_at: nil).to_a
  end

  def time_bonus_params_for_score
    {
      deadline_at: deadline_at,
      finished_at: finished_at,
      duration: paper.duration
    }
  end

  def handle_solve_completion(at)
    if finished?
      update!(score: calculated_score)
    elsif all_solved?
      close(at)
    end
  end

  def calculated_score
    solved = fetch_solved_challenges
    score_for_challenges(
      solved.map(&:challenge),
      all_solved: all_solved?,
      time_bonus_params: time_bonus_params_for_score
    )
  end
end
