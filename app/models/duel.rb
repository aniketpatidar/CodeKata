class Duel < ApplicationRecord
  belongs_to :challenger, class_name: "User"
  belongs_to :opponent, class_name: "User"
  belongs_to :challenge
  belongs_to :winner, class_name: "User", optional: true

  enum status: { pending: 0, active: 1, completed: 2 }

  validates :challenger_id, :opponent_id, :challenge_id, presence: true
  validate :challenger_cannot_be_opponent

  def participant?(user)
    challenger_id == user.id || opponent_id == user.id
  end

  def opponent_of(user)
    challenger_id == user.id ? opponent : challenger
  end

  def active?
    status == "active"
  end

  private

  def challenger_cannot_be_opponent
    if challenger_id == opponent_id
      errors.add(:opponent_id, "cannot duel themselves")
    end
  end
end
