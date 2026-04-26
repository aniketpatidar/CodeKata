# Provides AI-powered hints for coding challenges using Google's Gemini API
class GeminiService
  GEMINI_MODEL = "gemini-2.0-flash"

  def hint(challenge_description, user_code)
    raise ArgumentError, "Challenge description cannot be empty" if challenge_description.blank?
    raise ArgumentError, "Code cannot be empty" if user_code.blank?

    api_key = gemini_api_key
    raise KeyError, "GEMINI_API_KEY is not set" if api_key.nil?

    client = create_client

    prompt = build_prompt(challenge_description, user_code)

    response = client.chat(
      model: GEMINI_MODEL,
      messages: [{ role: "user", content: prompt }]
    )

    response.content
  rescue RubyLLM::AuthenticationError
    raise RubyLLM::AuthenticationError, "GEMINI_API_KEY is not configured or invalid"
  end

  private

  def create_client
    RubyLLM::Client.new(api_key: gemini_api_key)
  end

  def gemini_api_key
    ENV["GEMINI_API_KEY"]
  end

  def build_prompt(challenge_description, user_code)
    <<~PROMPT
      A coding student is working on this challenge:
      #{challenge_description}

      Their current code:
      ```ruby
      #{user_code}
      ```

      Provide a brief, helpful hint (2-3 sentences) to guide them without giving away the solution.
      Focus on what they should think about or try next.
    PROMPT
  end
end
