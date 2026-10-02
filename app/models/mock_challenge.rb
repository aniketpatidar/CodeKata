class MockChallenge < ApplicationRecord
  belongs_to :mock
  belongs_to :challenge

  validates :position, presence: true

  def solved? = solved_at.present?

  def starting_code
    code.presence || challenge.method_template.to_s.gsub("\\n", "\n")
  end
end
