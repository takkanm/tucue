# frozen_string_literal: true

module Tucue
  # curses ベースの TUI。キー入力ループと画面描画を担当する。
  # TODO: curses による描画と再生位置ポーリングを実装する。
  class UI
    def initialize(player, marker)
      @player = player
      @marker = marker
    end

    def run
      raise NotImplementedError
    end
  end
end
