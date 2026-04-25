class AppSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.ai_hints_enabled?
    find_by(key: "ai_hints_enabled")&.value || false
  end

  def self.enable_ai_hints!
    find_or_create_by(key: "ai_hints_enabled").update(value: true)
  end

  def self.disable_ai_hints!
    find_or_create_by(key: "ai_hints_enabled").update(value: false)
  end
end
