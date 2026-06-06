# frozen_string_literal: true

require "socket"
require "json"
require "timeout"

module Tucue
  # Playback engine that controls mpv over --input-ipc-server.
  #
  # Spawns mpv as a child process and talks to it through a Unix domain
  # socket, sending JSON IPC commands to seek and read the playback position.
  # https://mpv.io/manual/stable/#json-ipc
  class Player
    class Error < Tucue::Error; end

    # Max seconds to wait for the IPC socket to appear.
    SOCKET_TIMEOUT = 5

    def initialize(file, socket_path: "/tmp/tucue.sock")
      @file = file
      @socket_path = socket_path
      @pid = nil
      @socket = nil
      @request_id = 0
      @mutex = Mutex.new
    end

    attr_reader :file

    # Launch mpv and connect to its IPC socket.
    def start
      raise Error, "mpv not found in PATH" unless mpv_available?

      File.unlink(@socket_path) if File.exist?(@socket_path)

      @pid = spawn(
        "mpv",
        "--no-video",
        "--no-terminal",
        "--input-ipc-server=#{@socket_path}",
        @file
      )

      connect
      self
    end

    # Toggle between playing and paused.
    def toggle_pause
      command("cycle", "pause")
    end

    def play
      set_property("pause", false)
    end

    def pause
      set_property("pause", true)
    end

    def paused?
      get_property("pause") == true
    end

    # Seek relative to the current position (seconds; negative rewinds).
    def seek(seconds)
      command("seek", seconds, "relative")
    end

    # Current playback position in seconds, or nil if unavailable.
    def time_pos
      get_property("time-pos")
    end

    # Total duration in seconds, or nil if unavailable.
    def duration
      get_property("duration")
    end

    # Quit mpv and close the socket.
    def stop
      command("quit") if @socket
    rescue Error
      # Already gone; ignore.
    ensure
      close
    end

    private

    def mpv_available?
      ENV["PATH"].to_s.split(File::PATH_SEPARATOR).any? do |dir|
        File.executable?(File.join(dir, "mpv"))
      end
    end

    def connect
      Timeout.timeout(SOCKET_TIMEOUT) do
        loop do
          break if File.socket?(@socket_path)

          sleep 0.05
        end

        loop do
          @socket = UNIXSocket.new(@socket_path)
          break
        rescue Errno::ENOENT, Errno::ECONNREFUSED
          sleep 0.05
        end
      end
    rescue Timeout::Error
      raise Error, "timed out waiting for mpv IPC socket: #{@socket_path}"
    end

    # Send a command whose return value we don't care about.
    def command(*args)
      send_command(args)["error"] == "success"
    end

    def get_property(name)
      response = send_command(["get_property", name])
      response["error"] == "success" ? response["data"] : nil
    end

    def set_property(name, value)
      command("set_property", name, value)
    end

    # Send a JSON IPC command and return the matching response.
    # Requests and responses are paired by request_id; event messages
    # arriving in between are skipped.
    def send_command(args)
      raise Error, "player not started" unless @socket

      @mutex.synchronize do
        id = (@request_id += 1)
        @socket.puts(JSON.generate(command: args, request_id: id))

        loop do
          line = @socket.gets
          raise Error, "mpv connection closed" if line.nil?

          message = JSON.parse(line)
          return message if message["request_id"] == id
          # Anything else (events, etc.) is ignored.
        end
      end
    rescue Errno::EPIPE, IOError => e
      raise Error, "mpv IPC error: #{e.message}"
    end

    def close
      @socket&.close
      @socket = nil
      if @pid
        Process.wait(@pid)
      end
    rescue Errno::ECHILD, Errno::ESRCH
      # Already reaped.
    ensure
      @pid = nil
      File.unlink(@socket_path) if File.exist?(@socket_path)
    end
  end
end
