# frozen_string_literal: true

require "curses"

module Tucue
  # curses-based TUI handling the key-input loop and screen drawing.
  #
  # Rather than spawning a separate poll thread (curses is not thread-safe),
  # the main loop uses a getch timeout so the screen refreshes periodically
  # while still reacting to key presses promptly.
  class UI
    SEEK_SMALL = 5
    SEEK_LARGE = 15

    # getch timeout in ms; also the screen refresh interval.
    REFRESH_MS = 200

    PROGRESS_WIDTH = 24

    def initialize(player, marker)
      @player = player
      @marker = marker
      @status = ""
      @running = true
    end

    def run
      @player.start
      @status = "Playing #{File.basename(@player.file)}"
      with_curses do
        loop do
          begin
            draw
            handle_key(@window.getch)
          rescue Tucue::Error => e
            # The player connection dropped (e.g. mpv reached end of file
            # or exited); report it and leave the loop cleanly.
            @status = "Playback ended: #{e.message}"
            @running = false
          end
          break unless @running
        end
      end
    ensure
      @player.stop
    end

    private

    def with_curses
      Curses.init_screen
      Curses.curs_set(0)
      Curses.noecho
      Curses.stdscr.keypad(true)
      @window = Curses.stdscr
      @window.timeout = REFRESH_MS
      yield
    ensure
      Curses.close_screen
    end

    def handle_key(key)
      case key
      when " ", "p"
        @player.toggle_pause
        @status = @player.paused? ? "Paused" : "Playing"
      when Curses::Key::RIGHT
        @player.seek(SEEK_SMALL)
      when Curses::Key::LEFT
        @player.seek(-SEEK_SMALL)
      when "]"
        @player.seek(SEEK_LARGE)
      when "["
        @player.seek(-SEEK_LARGE)
      when "m"
        add_mark
      when "e"
        export
      when "q"
        @running = false
      end
    rescue Tucue::Error => e
      @status = "Error: #{e.message}"
    end

    def add_mark
      pos = @player.time_pos || 0
      label = prompt("Label (optional): ")
      label = nil if label.empty?
      @marker.add(pos, label)
      @status = "Marked #{format_time(pos)}#{label ? " - #{label}" : ""}"
    end

    def export
      path = "#{File.basename(@player.file, '.*')}.csv"
      @marker.export_csv(path)
      @status = "Exported #{@marker.marks.size} mark(s) to #{path}"
    rescue NotImplementedError
      @status = "Export not implemented yet"
    end

    # Read a line of input at the bottom of the screen.
    def prompt(message)
      Curses.curs_set(1)
      Curses.echo
      @window.setpos(@window.maxy - 1, 0)
      @window.clrtoeol
      @window.addstr(message)
      @window.timeout = -1 # block until the user finishes typing
      input = @window.getstr.to_s.strip
      input
    ensure
      @window.timeout = REFRESH_MS
      Curses.noecho
      Curses.curs_set(0)
    end

    def draw
      @window.erase
      row = 0
      @window.setpos(row, 0)
      @window.addstr("  File: #{File.basename(@player.file)}")

      row += 1
      pos = @player.time_pos
      dur = @player.duration
      @window.setpos(row, 0)
      @window.addstr("  #{format_time(pos)} / #{format_time(dur)}  #{progress_bar(pos, dur)}")

      row += 1
      @window.setpos(row, 0)
      @window.addstr("  " + ("-" * 40))

      [
        "[Space] play/pause",
        "[<-] -#{SEEK_SMALL}s   [->] +#{SEEK_SMALL}s",
        "[[] -#{SEEK_LARGE}s   []] +#{SEEK_LARGE}s",
        "[m] mark   [e] export",
        "[q] quit"
      ].each do |line|
        row += 1
        @window.setpos(row, 0)
        @window.addstr("  #{line}")
      end

      row += 1
      @window.setpos(row, 0)
      @window.addstr("  " + ("-" * 40))

      row += 1
      @window.setpos(row, 0)
      @window.addstr("  Marks (#{@marker.marks.size})")

      @marker.marks.each do |mark|
        row += 1
        break if row >= @window.maxy - 1

        label = mark.label ? " - #{mark.label}" : ""
        @window.setpos(row, 0)
        @window.addstr("  * #{format_time(mark.time)}#{label}")
      end

      @window.setpos(@window.maxy - 1, 0)
      @window.addstr("  #{@status}")
      @window.refresh
    end

    def progress_bar(pos, dur)
      return "-" * PROGRESS_WIDTH unless pos && dur && dur.positive?

      filled = [(pos.to_f / dur * PROGRESS_WIDTH).round, PROGRESS_WIDTH].min
      ("#" * filled) + ("-" * (PROGRESS_WIDTH - filled))
    end

    # Format seconds as HH:MM:SS.
    def format_time(seconds)
      return "--:--:--" if seconds.nil?

      total = seconds.to_i
      format("%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    end
  end
end
