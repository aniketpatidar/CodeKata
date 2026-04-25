class ChallengeCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :challenge

  validates :user_id, :challenge_id, presence: true
  validates :user_id, uniqueness: { scope: :challenge_id }
end
