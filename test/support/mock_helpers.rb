module MockHelpers
  # Challenges whose `tests` parse (fixture challenges' do not).
  def create_challenges!(difficulty, count)
    Array.new(count) do |i|
      Challenge.create!(
        name: "Mock #{difficulty} #{i} #{SecureRandom.hex(4)}",
        description: "Return the input unchanged.",
        language: "Ruby",
        difficulty: difficulty,
        method_template: "def solve(x)\\n  \\nend",
        tests: [{ "input" => "solve(1)", "expected_output" => "1" }]
      )
    end
  end

  # Makes Mock.start! prefer challenges created after this call.
  def mark_existing_challenges_solved!(user)
    Challenge.find_each { |challenge| ChallengeCompletion.find_or_create_by!(user: user, challenge: challenge) }
  end

  # Builds a Mock with an exact challenge list, bypassing the random picker.
  def build_mock!(user:, challenges:, paper_key: "sprint", started_at: Time.current)
    paper = MockPaper.find(paper_key)
    mock = Mock.create!(user: user, paper_key: paper_key, started_at: started_at, deadline_at: started_at + paper.duration)
    challenges.each.with_index(1) { |challenge, position| mock.mock_challenges.create!(challenge: challenge, position: position) }
    mock
  end
end
