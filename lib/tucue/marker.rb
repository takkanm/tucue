# frozen_string_literal: true

module Tucue
  # マークの登録と CSV / JSON へのエクスポートを担う。
  # TODO: 実際のエクスポート処理を実装する。
  class Marker
    Mark = Struct.new(:time, :label)

    def initialize
      @marks = []
    end

    attr_reader :marks

    def add(time, label = nil)
      @marks << Mark.new(time, label)
    end

    def export_csv(path)
      raise NotImplementedError
    end

    def export_json(path)
      raise NotImplementedError
    end
  end
end
