# frozen_string_literal: true

module Tucue
  # mpv を --input-ipc-server 経由で制御する再生エンジン。
  # TODO: mpv プロセスの起動とソケット接続を実装する。
  class Player
    def initialize(file, socket_path: "/tmp/tucue.sock")
      @file = file
      @socket_path = socket_path
    end

    def start
      raise NotImplementedError
    end

    def toggle_pause
      raise NotImplementedError
    end

    def seek(seconds)
      raise NotImplementedError
    end

    def time_pos
      raise NotImplementedError
    end

    def duration
      raise NotImplementedError
    end

    def stop
      raise NotImplementedError
    end
  end
end
