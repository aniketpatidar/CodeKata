class ChallengeSelector
  def initialize(user, paper)
    @user = user
    @paper = paper
  end

  def call
    @paper.mix.flat_map { |difficulty, count| pick_for(difficulty, count) }
  end

  private

  def pick_for(difficulty, count)
    unsolved = unsolved_challenges(difficulty).limit(count).to_a
    solved = solved_challenges(difficulty).limit(count - unsolved.size).to_a
    picked = unsolved + solved
    raise Mock::NotEnoughChallenges, "#{@paper.name} needs #{count} #{difficulty} challenges" if picked.size < count
    picked
  end

  def unsolved_challenges(difficulty)
    Challenge.where(difficulty: difficulty)
      .where.not(id: solved_ids)
      .order("RANDOM()")
  end

  def solved_challenges(difficulty)
    Challenge.where(difficulty: difficulty)
      .where(id: solved_ids)
      .order("RANDOM()")
  end

  def solved_ids
    @solved_ids ||= @user.challenge_completions.select(:challenge_id)
  end
end
