require "test_helper"
require "minitest/mock"

# Stub RubyLLM if not available
unless defined?(RubyLLM)
  module RubyLLM
    class Client
      def initialize(api_key:); end

      def chat(**options); end
    end

    class AuthenticationError < StandardError; end
  end
end

class GeminiServiceTest < Minitest::Test
  def setup
    @service = GeminiService.new
    @original_api_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = "test_api_key_12345"
  end

  def teardown
    if @original_api_key.nil?
      ENV.delete("GEMINI_API_KEY")
    else
      ENV["GEMINI_API_KEY"] = @original_api_key
    end
  end

  def test_hint_returns_a_string_hint_for_challenge_and_code
    challenge_desc = "Write a function that adds two numbers"
    code = "def add(a, b)\n  # your code here\nend"

    response_text = "Consider using the + operator to combine the two parameters."
    mock_client_with_response(response_text)

    hint = @service.hint(challenge_desc, code)

    assert_kind_of String, hint
    assert_equal response_text, hint
  end

  def test_hint_includes_relevant_guidance
    challenge_desc = "Reverse a string"
    code = "def reverse_string(s)\n  \nend"

    response_text = "Think about string methods in Ruby that can help reverse text. Try exploring the String class methods."
    mock_client_with_response(response_text)

    hint = @service.hint(challenge_desc, code)

    assert hint.downcase.include?("string"), "Hint should relate to the challenge"
  end

  def test_hint_uses_challenge_description_and_user_code_in_prompt
    challenge_desc = "Write a function that adds two numbers"
    code = "def add(a, b)\n  a + b\nend"

    mock_client_with_response("Here's your hint text")

    hint = @service.hint(challenge_desc, code)

    assert_kind_of String, hint
    assert_equal "Here's your hint text", hint
  end

  def test_hint_raises_error_when_GEMINI_API_KEY_is_missing
    ENV.delete("GEMINI_API_KEY")
    service = GeminiService.new

    assert_raises(KeyError) do
      service.hint("Challenge description", "code")
    end
  end

  def test_hint_handles_RubyLLM_AuthenticationError_gracefully
    challenge_desc = "Test challenge"
    code = "test code"

    mock_client_with_error(RubyLLM::AuthenticationError.new("Invalid API key"))

    assert_raises(RubyLLM::AuthenticationError) do
      @service.hint(challenge_desc, code)
    end
  end

  def test_hint_generates_prompt_with_challenge_description_and_code
    challenge_desc = "Reverse a string"
    code = "def reverse(s)\n  s.reverse\nend"

    captured_prompt = nil

    # Create a mock client that captures the prompt
    mock_response = Object.new
    def mock_response.content
      "Your hint here"
    end

    mock_client = Object.new
    mock_client.instance_variable_set(:@captured_prompt, nil)

    def mock_client.chat(model:, messages:)
      @captured_prompt = messages[0][:content]
      mock_response_obj = Object.new
      def mock_response_obj.content
        "Your hint here"
      end
      mock_response_obj
    end

    # Inject the mock client
    @service.define_singleton_method(:create_client) do
      mock_client
    end

    @service.hint(challenge_desc, code)

    captured_prompt = mock_client.instance_variable_get(:@captured_prompt)

    assert captured_prompt, "Should have captured prompt"
    assert_match(/Reverse a string/, captured_prompt)
    assert_match(/def reverse/, captured_prompt)
    assert_match(/helpful hint/, captured_prompt)
  end

  private

  def mock_client_with_response(response_text)
    mock_response = Object.new
    def mock_response.content
      @response_text
    end
    mock_response.instance_variable_set(:@response_text, response_text)

    mock_client = Object.new
    def mock_client.chat(model:, messages:)
      @mock_response
    end
    mock_client.instance_variable_set(:@mock_response, mock_response)

    @service.define_singleton_method(:create_client) do
      mock_client
    end
  end

  def mock_client_with_error(error)
    mock_client = Object.new
    mock_client.instance_variable_set(:@error, error)
    def mock_client.chat(model:, messages:)
      raise @error
    end

    @service.define_singleton_method(:create_client) do
      mock_client
    end
  end
end
