# frozen_string_literal: true

module Tucue
  # curses-based TUI handling the key-input loop and screen drawing.
  # TODO: implement curses rendering and playback-position polling.
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
