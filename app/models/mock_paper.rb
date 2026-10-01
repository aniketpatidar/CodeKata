class MockPaper < Data.define(:key, :name, :mix, :duration)
  ALL = [
    new(key: "sprint",   name: "Sprint",   mix: { easy: 3 },            duration: 20.minutes),
    new(key: "standard", name: "Standard", mix: { easy: 2, medium: 2 }, duration: 45.minutes),
    new(key: "marathon", name: "Marathon", mix: { easy: 2, medium: 4 }, duration: 90.minutes)
  ].freeze

  def self.all = ALL

  def self.find(key)
    ALL.find { |paper| paper.key == key.to_s }
  end

  def challenge_count = mix.values.sum

  def mix_label
    mix.map { |difficulty, count| "#{count} #{difficulty}" }.join(" + ")
  end
end
