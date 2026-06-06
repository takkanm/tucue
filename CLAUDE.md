# tucue

## Overview

A Ruby TUI application for playing local audio files, marking specific
moments, and exporting them.

- **gem name**: `tucue` (a blend of TUI + Cue, pronounced "too-cue")
- **RubyGems**: publishing is planned (check name availability on rubygems.org)

---

## Conventions

- **Code comments**: English.
- **README and other distributed docs**: English.
- **Commit messages**: English.
- **UI strings**: English.

---

## Features

- [x] Play mp3 / wav files
- [x] Rewind / fast-forward in 5- and 15-second steps
- [x] Mark the current position (with an optional label)
- [x] Export the mark list to a file (CSV / JSON)

---

## Technical approach

### Playback engine
- Delegate to **mpv** (`brew install mpv` is a prerequisite).
- Open a Unix socket with `--input-ipc-server` and control it by sending
  JSON commands from Ruby.

```bash
mpv --input-ipc-server=/tmp/tucue.sock target.mp3
```

```ruby
# Seeking
socket.puts({ command: ["seek", 15, "relative"] }.to_json)
socket.puts({ command: ["seek", -5, "relative"] }.to_json)

# Get the current position
socket.puts({ command: ["get_property", "time-pos"] }.to_json)
```

IPC notes (see `lib/tucue/player.rb`):
- Pair requests and responses by `request_id`; skip `event` messages that
  arrive in between.
- Guard socket sends with a `Mutex` so callers can share the socket safely.
- Treat a dropped connection (mpv reaching EOF or exiting) as a clean
  shutdown rather than an error.

### TUI
- Built on **curses** (bundled with Ruby).
- Optionally combine with the **tty-\* family** (`tty-cursor`, `tty-screen`,
  `tty-box`).
- The UI uses a `getch` timeout to refresh the playback position
  periodically instead of a separate poll thread, because curses is not
  thread-safe. (This differs from the original "sub-thread polling" idea.)

### Export formats
- CSV (default)
- JSON (option)

---

## UI sketch

```
┌─────────────────────────────────┐
│  File: interview.mp3            │
│  00:01:23 / 00:45:10  ####----  │
├─────────────────────────────────┤
│  [Space] play/pause             │
│  [<-] -5s   [->] +5s            │
│  [[] -15s   []] +15s            │
│  [m] mark   [e] export          │
│  [q] quit                       │
├─────────────────────────────────┤
│  Marks (2)                      │
│  * 00:01:23 - key point         │
│  * 00:03:45                     │
└─────────────────────────────────┘
```

---

## Key bindings

| Key | Action |
|---|---|
| `Space` / `p` | Play / pause |
| `→` | +5 seconds |
| `←` | -5 seconds |
| `]` | +15 seconds |
| `[` | -15 seconds |
| `m` | Mark the current position |
| `e` | Export the marks |
| `q` | Quit |

---

## Gem layout

```
tucue/
├── CLAUDE.md
├── README.md
├── LICENSE
├── tucue.gemspec
├── Gemfile
├── bin/
│   └── tucue          # entry point (CLI command)
└── lib/
    ├── tucue.rb       # requires and Tucue::Error
    └── tucue/
        ├── version.rb
        ├── cli.rb     # argument parsing / entry point
        ├── player.rb  # mpv control
        ├── ui.rb      # curses TUI
        └── marker.rb  # mark management / export
```

---

## Usage

```bash
bundle exec tucue interview.mp3
bundle exec tucue --start 01:02:03 interview.mp3
```

CLI options (parsed in `lib/tucue/cli.rb`):
- `-s`, `--start TIME` — start playback at `TIME` (`SS`, `MM:SS`, or
  `HH:MM:SS`). Implemented via mpv's `--start=` and `Player#start_at`.
- `-v`, `--version`; `-h`, `--help`.

---

## Environment / prerequisites

- macOS (developer environment)
- Ruby 3.x or later
- mpv (`brew install mpv`)

---

## Licensing

- tucue's own code is released under the **MIT License**.
- mpv is GPL/LGPL, but it runs as a **separate process** and is **not
  bundled** with tucue, so its copyleft does not extend to tucue's source.
  Do not redistribute mpv binaries inside the gem.
