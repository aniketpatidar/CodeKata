require "test_helper"

class MocksHelperTest < ActionView::TestCase
  test "clock formats seconds as mm:ss" do
    assert_equal "00:00", clock(0)
    assert_equal "01:05", clock(65)
    assert_equal "90:00", clock(5400)
    assert_equal "00:59", clock(59.4)
  end
end
