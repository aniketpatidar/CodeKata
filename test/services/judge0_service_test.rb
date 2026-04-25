require "test_helper"
require "minitest/mock"

class Judge0ServiceTest < Minitest::Test
  def setup
    @service = Judge0Service.new
    @original_api_key = ENV["JUDGE0_API_KEY"]
    ENV["JUDGE0_API_KEY"] = "test_api_key_12345"
  end

  def teardown
    if @original_api_key.nil?
      ENV.delete("JUDGE0_API_KEY")
    else
      ENV["JUDGE0_API_KEY"] = @original_api_key
    end
  end

  def test_run_tests_returns_hash_with_test_results
    code = "def add(a, b)\n  a + b\nend"
    tests = [
      { input: "add(2, 3)", expected_output: "5" },
      { input: "add(0, 0)", expected_output: "0" }
    ]

    mock_judge0_execute(2, ["5", "0"])

    results = @service.run_tests(code, tests, "add")

    assert_kind_of Hash, results
    assert_equal 2, results.size
    assert results.values.all? { |r| r.is_a?(Hash) && r.has_key?(:passed) }
  end

  def test_run_tests_marks_test_as_passed_when_output_matches
    code = "def greet\n  'hello'\nend"
    tests = [{ input: "greet()", expected_output: "hello" }]

    mock_judge0_execute(1, ["hello"])

    results = @service.run_tests(code, tests, "greet")

    assert results.values.first[:passed], "Test should pass when output matches"
  end

  def test_run_tests_marks_test_as_failed_when_output_doesnt_match
    code = "def add(a, b)\n  a - b\nend"
    tests = [{ input: "add(5, 3)", expected_output: "8" }]

    mock_judge0_execute(1, ["2"])

    results = @service.run_tests(code, tests, "add")

    refute results.values.first[:passed], "Test should fail when output doesn't match"
  end

  def test_run_tests_raises_KeyError_when_JUDGE0_API_KEY_is_missing
    ENV.delete("JUDGE0_API_KEY")
    service = Judge0Service.new
    code = "def test; end"
    tests = [{ input: "test()", expected_output: "" }]

    assert_raises KeyError do
      service.run_tests(code, tests, "test")
    end
  end

  def test_run_tests_includes_error_message_when_Judge0_returns_stderr
    code = "def test; raise 'error'; end"
    tests = [{ input: "test()", expected_output: "" }]

    mock_judge0_with_error(1, [""], ["Error: undefined method"])

    results = @service.run_tests(code, tests, "test")

    assert results.values.first.key?(:error)
    assert_match(/Error/, results.values.first[:error])
  end

  def test_run_tests_includes_actual_output_in_result
    code = "puts 'hello world'"
    tests = [{ input: "", expected_output: "hello world" }]

    mock_judge0_execute(1, ["hello world"])

    results = @service.run_tests(code, tests, "test")

    assert_equal "hello world", results.values.first[:output]
  end

  def test_run_tests_includes_expected_output_in_result
    code = "puts 'wrong'"
    tests = [{ input: "", expected_output: "right" }]

    mock_judge0_execute(1, ["wrong"])

    results = @service.run_tests(code, tests, "test")

    assert_equal "right", results.values.first[:expected]
  end

  def test_run_tests_handles_nil_response_gracefully
    code = "def test; end"
    tests = [{ input: "test()", expected_output: "" }]

    stub_judge0_error

    results = @service.run_tests(code, tests, "test")

    refute results.values.first[:passed]
    assert_match(/No response/, results.values.first[:error])
  end

  private

  def mock_judge0_execute(count, outputs)
    errors = Array.new(count, nil)
    mock_judge0_with_error(count, outputs, errors)
  end

  def mock_judge0_with_error(count, outputs, errors)
    submission_ids = (1..count).map { |i| i }

    @service.define_singleton_method(:submit_to_judge0) do |code, api_key|
      submission_ids.shift
    end

    call_count = 0
    @service.define_singleton_method(:poll_judge0_result) do |submission_id, api_key|
      idx = call_count
      call_count += 1
      {
        "id" => submission_id,
        "status" => { "id" => 3, "description" => "Accepted" },
        "stdout" => outputs[idx],
        "stderr" => errors[idx]
      }
    end
  end

  def stub_judge0_error
    @service.define_singleton_method(:submit_to_judge0) do |code, api_key|
      nil
    end

    @service.define_singleton_method(:poll_judge0_result) do |submission_id, api_key|
      nil
    end
  end
end
