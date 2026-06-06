# frozen_string_literal: true

require_relative "lib/tucue/version"

Gem::Specification.new do |spec|
  spec.name          = "tucue"
  spec.version       = Tucue::VERSION
  spec.authors       = ["takkanm"]
  spec.email         = ["takkanm@gmail.com"]

  spec.summary       = "TUI audio player for marking and exporting cue points."
  spec.description   = "tucue plays local audio files (mp3/wav) in a terminal UI, " \
                       "lets you mark timestamps with optional labels, and export " \
                       "them as CSV or JSON. Playback is delegated to mpv."
  spec.homepage      = "https://github.com/takkanm/tucue"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*.rb", "bin/*", "*.gemspec", "Gemfile", "README.md", "LICENSE", "CLAUDE.md"]
  spec.bindir        = "bin"
  spec.executables   = ["tucue"]
  spec.require_paths = ["lib"]

  spec.add_dependency "curses", "~> 1.4"
end
