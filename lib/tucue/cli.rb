# frozen_string_literal: true

require "optparse"

module Tucue
  # Command-line entry point: parses arguments and launches the TUI.
  class CLI
    # Run with the given argv. Returns a process exit status (0 = success).
    def self.start(argv)
      new.start(argv)
    end

    def start(argv)
      options = parse(argv)
      file = argv.shift

      unless file
        warn "usage: tucue [options] FILE"
        return 1
      end

      unless File.exist?(file)
        warn "tucue: file not found: #{file}"
        return 1
      end

      player = Player.new(file, start_at: options[:start_at])
      marker = Marker.new
      UI.new(player, marker).run
      0
    rescue OptionParser::ParseError, ArgumentError => e
      warn "tucue: #{e.message}"
      1
    end

    # Parse "SS", "MM:SS", or "HH:MM:SS" (seconds may be fractional) into a
    # number of seconds. Returns nil for nil input; raises ArgumentError on a
    # malformed value.
    def self.parse_time(value)
      return nil if value.nil?

      parts = value.to_s.split(":", -1)
      unless (1..3).cover?(parts.size) && parts.all? { |p| p.match?(/\A\d+(\.\d+)?\z/) }
        raise ArgumentError, "invalid time: #{value.inspect} (use SS, MM:SS, or HH:MM:SS)"
      end

      parts.map(&:to_f).reduce(0.0) { |acc, part| acc * 60 + part }
    end

    private

    def parse(argv)
      options = {}
      parser = OptionParser.new do |o|
        o.banner = "usage: tucue [options] FILE"
        o.on("-s", "--start TIME", "Start playback at TIME (e.g. 90, 1:30, 01:02:03)") do |v|
          options[:start_at] = self.class.parse_time(v)
        end
        o.on("-v", "--version", "Show version") do
          puts Tucue::VERSION
          exit 0
        end
        o.on("-h", "--help", "Show this help") do
          puts o
          exit 0
        end
      end
      parser.parse!(argv)
      options
    end
  end
end
