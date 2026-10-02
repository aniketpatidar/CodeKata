module MocksHelper
  def clock(seconds)
    total = seconds.to_i
    format("%02d:%02d", total / 60, total % 60)
  end

  def challenge_difficulty_badge(difficulty)
    tag.span(
      difficulty,
      class: "ck-chip ck-chip--#{difficulty}"
    )
  end

  def challenge_status_badge(challenge, solved_at: nil)
    content = badge_content(challenge, solved_at)
    tag.span(content, class: "ck-chip ck-chip--#{challenge.difficulty}")
  end

  private

  def badge_content(challenge, solved_at)
    solved_at ? "✓ #{challenge.difficulty}" : challenge.difficulty
  end
end
