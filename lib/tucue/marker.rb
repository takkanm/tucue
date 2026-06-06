# frozen_string_literal: true

require "csv"
require "json"

module Tucue
  # Records marks and exports them to CSV / JSON.
  class Marker
    # A single mark: +time+ is the playback position in seconds and
    # +label+ is an optional user-supplied note.
    Mark = Struct.new(:time, :label) do
      # Format the time as HH:MM:SS.
      def timestamp
        total = time.to_i
        format("%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
      end

      def to_h
        {timestamp: timestamp, seconds: time.to_f.round(3), label: label}
      end
    end

    CSV_HEADERS = %w[timestamp seconds label].freeze

    def initialize
      @marks = []
    end

    attr_reader :marks

    # Append a mark at +time+ seconds with an optional +label+.
    def add(time, label = nil)
      label = nil if label.is_a?(String) && label.strip.empty?
      mark = Mark.new(time, label)
      @marks << mark
      mark
    end

    def empty?
      @marks.empty?
    end

    # Write the marks to +path+ as CSV and return the path.
    def export_csv(path)
      CSV.open(path, "w") do |csv|
        csv << CSV_HEADERS
        @marks.each do |mark|
          csv << [mark.timestamp, mark.time.to_f.round(3), mark.label]
        end
      end
      path
    end

    # Write the marks to +path+ as JSON and return the path.
    def export_json(path)
      File.write(path, JSON.pretty_generate(@marks.map(&:to_h)))
      path
    end
  end
end
