# frozen_string_literal: true

require_relative "test_helper"

class CLITest < Minitest::Test
  def test_parse_time_nil
    assert_nil Tucue::CLI.parse_time(nil)
  end

  def test_parse_time_seconds_only
    assert_in_delta 90.0, Tucue::CLI.parse_time("90")
    assert_in_delta 5.5, Tucue::CLI.parse_time("5.5")
  end

  def test_parse_time_mm_ss
    assert_in_delta 90.0, Tucue::CLI.parse_time("1:30")
    assert_in_delta 125.0, Tucue::CLI.parse_time("02:05")
  end

  def test_parse_time_hh_mm_ss
    assert_in_delta 3723.0, Tucue::CLI.parse_time("01:02:03")
    assert_in_delta 3661.5, Tucue::CLI.parse_time("1:01:01.5")
  end

  def test_parse_time_rejects_garbage
    assert_raises(ArgumentError) { Tucue::CLI.parse_time("abc") }
    assert_raises(ArgumentError) { Tucue::CLI.parse_time("1:2:3:4") }
    assert_raises(ArgumentError) { Tucue::CLI.parse_time("") }
  end

  def test_start_without_file_returns_error
    out, = capture_io { @status = Tucue::CLI.start([]) }
    assert_equal 1, @status
  end

  def test_start_with_missing_file_returns_error
    capture_io { @status = Tucue::CLI.start(["does_not_exist.mp3"]) }
    assert_equal 1, @status
  end

  def test_start_with_invalid_start_option_returns_error
    Dir.mktmpdir do |dir|
      path = TestHelpers.write_silent_wav(File.join(dir, "a.wav"))
      capture_io { @status = Tucue::CLI.start(["--start", "nope", path]) }
      assert_equal 1, @status
    end
  end
end
