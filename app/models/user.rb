class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  has_many :posts, dependent: :destroy
  has_one_attached :avatar
  validates :slug, uniqueness: true
  validates :score, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :avatar_must_be_image, if: -> { avatar.attached? && avatar.changed? }

  IMAGE_CONTENT_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  before_validation :set_slug, if: -> { slug.nil? }

  scope :top_10_by_score, -> { order(score: :desc).limit(10) }

  has_many :invitations
  has_many :pending_invitations, -> { where confirmed: false }, class_name: 'Invitation', foreign_key: "friend_id"
  has_many :notifications, dependent: :destroy
  has_many :discussions, dependent: :destroy
  has_many :challenge_completions, dependent: :destroy
  has_many :games_as_challenger, class_name: "Game", foreign_key: :challenger_id, dependent: :destroy
  has_many :games_as_opponent,   class_name: "Game", foreign_key: :opponent_id,   dependent: :destroy
  has_many :mocks, dependent: :destroy
  acts_as_voter

  def friends
    sent     = Invitation.where(user_id: id, confirmed: true).select(:friend_id)
    received = Invitation.where(friend_id: id, confirmed: true).select(:user_id)
    User.where(id: sent).or(User.where(id: received))
  end

  def friend_with?(user)
    Invitation.confirmed_record?(id, user.id)
  end

  def send_invitation(user)
    invitations.create(friend_id: user.id)
  end

  def sent_invitations
    Invitation.where(user_id: id, confirmed: false)
  end

  def received_invitations
    Invitation.where(friend_id: id, confirmed: false)
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  def initials
    [first_name[0].upcase, last_name[0].upcase].join
  end

  def self.search(params)
    params[:query].blank? ? all : where(
      "slug LIKE ?", "%#{sanitize_sql_like(params[:query])}%"
    )
  end

  def to_param
    slug
  end

  def admin?
    id == 1
  end

  private

  def set_slug
    if User.find_by(slug: full_name.parameterize)
      self.slug = full_name.parameterize + SecureRandom.hex(6)
    else
      self.slug = full_name.parameterize
    end
  end

  def avatar_must_be_image
    unless IMAGE_CONTENT_TYPES.include?(avatar.blob.content_type)
      errors.add(:avatar, "must be an image (JPEG, PNG, GIF, or WebP)")
      avatar.purge
    end
  end
end
