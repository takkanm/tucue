# frozen_string_literal: true

require_relative "test_helper"

# Integration tests that drive a real mpv process over its JSON IPC socket.
# Skipped when mpv is not installed. --ao=null keeps playback going without
# depending on an audio device, so timing assertions stay deterministic.
class PlayerTest < Minitest::Test
  def setup
    skip "mpv not installed" unless TestHelpers.mpv_available?

    @dir = Dir.mktmpdir
    @wav = TestHelpers.write_silent_wav(File.join(@dir, "tone.wav"), seconds: 3)
    @socket = File.join(@dir, "tucue.sock")
    @player = Tucue::Player.new(@wav, socket_path: @socket, extra_args: ["--ao=null"])
    @player.start
    wait_until { @player.duration }
  end

  def teardown
    @player&.stop
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  def test_reports_duration
    assert_in_delta 3.0, @player.duration, 0.2
  end

  def test_starts_unpaused
    refute_predicate @player, :paused?
  end

  def test_toggle_pause
    @player.toggle_pause
    assert_predicate @player, :paused?

    @player.toggle_pause
    refute_predicate @player, :paused?
  end

  def test_relative_seek_moves_position_by_the_offset
    @player.pause # freeze the position so the delta is stable
    wait_until { @player.time_pos }
    before = @player.time_pos

    @player.seek(1)
    after = stable_time_pos

    assert_in_delta before + 1.0, after, 0.3
  end

  def test_negative_seek_rewinds
    @player.pause
    @player.seek(2)
    high = stable_time_pos

    @player.seek(-1)
    low = stable_time_pos

    assert_operator low, :<, high
  end

  def test_stop_removes_socket_file
    @player.stop

    refute File.exist?(@socket)
  end

  def test_start_at_begins_near_the_given_position
    @player.stop

    socket = File.join(@dir, "tucue2.sock")
    player = Tucue::Player.new(@wav, socket_path: socket, start_at: 1.5, extra_args: ["--ao=null"])
    player.start
    player.pause
    deadline = Time.now + 3
    sleep 0.02 until player.time_pos || Time.now > deadline

    assert_in_delta 1.5, player.time_pos, 0.3
  ensure
    player&.stop
  end

  private

  def wait_until(timeout: 3)
    deadline = Time.now + timeout
    sleep 0.02 until yield || Time.now > deadline
  end

  # Poll time_pos until it stops changing, so we read the position after a
  # seek has settled rather than mid-flight.
  def stable_time_pos(timeout: 3)
    deadline = Time.now + timeout
    last = nil
    loop do
      current = @player.time_pos
      return current if current && current == last
      return current if Time.now > deadline

      last = current
      sleep 0.05
    end
  end
end
