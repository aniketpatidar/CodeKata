require "net/http"
require "json"

class Judge0Service
  BASE_URL = "https://judge0-ce.p.rapidapi.com"
  LANGUAGE_ID = 71  # Ruby language ID in Judge0

  def run_tests(code, tests, method_name)
    api_key = judge0_api_key
    raise KeyError, "JUDGE0_API_KEY is not set" if api_key.nil?

    results = {}

    tests.each_with_index do |test, idx|
      result = execute_test(code, test, method_name, api_key)
      results["test_#{idx}"] = result
    end

    results
  end

  private

  def judge0_api_key
    ENV["JUDGE0_API_KEY"]
  end

  def execute_test(code, test, method_name, api_key)
    wrapped_code = wrap_code_with_test(code, test, method_name)
    submission_id = submit_to_judge0(wrapped_code, api_key)
    result = poll_judge0_result(submission_id, api_key)
    parse_judge0_result(result, test)
  end

  def wrap_code_with_test(code, test, method_name)
    <<~RUBY
      #{code}

      result = eval("#{test[:input]}")
      puts result.to_s
    RUBY
  end

  def submit_to_judge0(code, api_key)
    uri = URI("#{BASE_URL}/submissions?wait=false")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request["x-rapidapi-host"] = "judge0-ce.p.rapidapi.com"
    request["x-rapidapi-key"] = api_key

    request.body = JSON.generate({
      source_code: code,
      language_id: LANGUAGE_ID,
      stdin: ""
    })

    response = http.request(request)
    JSON.parse(response.body)["id"]
  rescue => e
    Rails.logger.error("Judge0 submission failed: #{e.message}")
    nil
  end

  def poll_judge0_result(submission_id, api_key)
    uri = URI("#{BASE_URL}/submissions/#{submission_id}")
    max_attempts = 30
    attempt = 0

    loop do
      attempt += 1
      break if attempt > max_attempts

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request["x-rapidapi-host"] = "judge0-ce.p.rapidapi.com"
      request["x-rapidapi-key"] = api_key

      response = http.request(request)
      result = JSON.parse(response.body)

      return result if result["status"]["id"] > 2

      sleep(0.5)
    end

    nil
  rescue => e
    Rails.logger.error("Judge0 result polling failed: #{e.message}")
    nil
  end

  def parse_judge0_result(judge0_result, test)
    return { passed: false, output: "", error: "No response from Judge0" } if judge0_result.nil?

    output = judge0_result["stdout"].to_s.strip
    expected = test[:expected_output].to_s.strip

    {
      passed: output == expected,
      output: output,
      expected: expected,
      error: judge0_result["stderr"]
    }
  end
end
