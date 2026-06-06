# frozen_string_literal: true

require_relative "test_helper"
require "csv"
require "json"

class MarkerTest < Minitest::Test
  def setup
    @marker = Tucue::Marker.new
  end

  def test_new_marker_is_empty
    assert_empty @marker.marks
    assert_predicate @marker, :empty?
  end

  def test_add_stores_time_and_label
    mark = @marker.add(83, "important")

    assert_equal 1, @marker.marks.size
    assert_equal 83, mark.time
    assert_equal "important", mark.label
    refute_predicate @marker, :empty?
  end

  def test_add_without_label_defaults_to_nil
    mark = @marker.add(42)

    assert_nil mark.label
  end

  def test_blank_label_is_normalized_to_nil
    assert_nil @marker.add(1, "").label
    assert_nil @marker.add(2, "   ").label
  end

  def test_timestamp_formats_as_hh_mm_ss
    assert_equal "00:01:23", Tucue::Marker::Mark.new(83, nil).timestamp
    assert_equal "00:45:10", Tucue::Marker::Mark.new(2710.9, nil).timestamp
    assert_equal "01:01:01", Tucue::Marker::Mark.new(3661, nil).timestamp
  end

  def test_export_csv_writes_header_and_rows
    @marker.add(83, "important")
    @marker.add(225.5)

    Dir.mktmpdir do |dir|
      path = File.join(dir, "marks.csv")
      assert_equal path, @marker.export_csv(path)

      rows = CSV.read(path)
      assert_equal Tucue::Marker::CSV_HEADERS, rows[0]
      assert_equal ["00:01:23", "83.0", "important"], rows[1]
      assert_equal ["00:03:45", "225.5", nil], rows[2]
    end
  end

  def test_export_json_writes_array_of_objects
    @marker.add(83, "important")
    @marker.add(225.5)

    Dir.mktmpdir do |dir|
      path = File.join(dir, "marks.json")
      assert_equal path, @marker.export_json(path)

      data = JSON.parse(File.read(path))
      assert_equal 2, data.size
      assert_equal({ "timestamp" => "00:01:23", "seconds" => 83.0, "label" => "important" }, data[0])
      assert_equal({ "timestamp" => "00:03:45", "seconds" => 225.5, "label" => nil }, data[1])
    end
  end

  def test_export_empty_marker
    Dir.mktmpdir do |dir|
      csv_path = @marker.export_csv(File.join(dir, "marks.csv"))
      json_path = @marker.export_json(File.join(dir, "marks.json"))

      assert_equal [Tucue::Marker::CSV_HEADERS], CSV.read(csv_path)
      assert_empty JSON.parse(File.read(json_path))
    end
  end
end
