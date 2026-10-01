require "test_helper"

class MockPaperTest < ActiveSupport::TestCase
  test "defines sprint, standard and marathon in order" do
    assert_equal %w[sprint standard marathon], MockPaper.all.map(&:key)
  end

  test "find returns the paper for a key, nil for unknown keys" do
    assert_equal "Standard", MockPaper.find("standard").name
    assert_equal "Standard", MockPaper.find(:standard).name
    assert_nil MockPaper.find("nope")
  end

  test "challenge_count sums the mix" do
    assert_equal 3, MockPaper.find("sprint").challenge_count
    assert_equal 4, MockPaper.find("standard").challenge_count
    assert_equal 6, MockPaper.find("marathon").challenge_count
  end

  test "mix_label describes the mix" do
    assert_equal "2 easy + 2 medium", MockPaper.find("standard").mix_label
  end

  test "durations" do
    assert_equal 20.minutes, MockPaper.find("sprint").duration
    assert_equal 45.minutes, MockPaper.find("standard").duration
    assert_equal 90.minutes, MockPaper.find("marathon").duration
  end
end
