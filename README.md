# tucue

A Ruby TUI application for playing local audio files, marking specific
moments, and exporting them. Handy for managing cue points in interview
recordings and similar audio.

The name is a blend of **TUI** and **Cue** (pronounced "too-cue").

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

## Features

- Play audio files such as mp3 / wav
- Rewind and fast-forward in 5- and 15-second steps
- Mark the current position with an optional label
- Export the mark list as CSV or JSON

## Requirements

- macOS (developer environment)
- Ruby 3.x or later
- [mpv](https://mpv.io/) (used as the playback engine)

```bash
brew install mpv
```

## Installation

Clone the repository and run bundle install.

```bash
git clone https://github.com/takkanm/tucue.git
cd tucue
bundle install
```

## Usage

```bash
bundle exec tucue interview.mp3
```

This launches the TUI and starts playback.

### Options

| Option | Description |
|---|---|
| `-s`, `--start TIME` | Start playback at `TIME`. Accepts `SS`, `MM:SS`, or `HH:MM:SS` (e.g. `90`, `1:30`, `01:02:03`). |
| `-v`, `--version` | Show the version. |
| `-h`, `--help` | Show help. |

```bash
bundle exec tucue --start 01:02:03 interview.mp3
```

## Key bindings

| Key | Action |
|---|---|
| `Space` / `p` | Play / pause |
| `→` | +5 seconds |
| `←` | -5 seconds |
| `]` | +15 seconds |
| `[` | -15 seconds |
| `m` | Mark the current position (prompts for an optional label) |
| `e` | Export the marks |
| `q` | Quit |

## Export

Pressing `e` writes the current marks to a `.csv` file named after the
audio file.

### CSV

```csv
timestamp,seconds,label
00:01:23,83.0,key point
00:03:45,225.5,
```

### JSON

JSON export is also supported (`Tucue::Marker#export_json`).

```json
[
  {
    "timestamp": "00:01:23",
    "seconds": 83.0,
    "label": "key point"
  },
  {
    "timestamp": "00:03:45",
    "seconds": 225.5,
    "label": null
  }
]
```

## Architecture

| File | Responsibility |
|---|---|
| `bin/tucue` | CLI entry point |
| `lib/tucue/player.rb` | Playback engine controlling mpv over JSON IPC (Unix socket) |
| `lib/tucue/ui.rb` | curses-based TUI and key-input loop |
| `lib/tucue/marker.rb` | Mark management and CSV / JSON export |

mpv is launched with `--input-ipc-server` and controlled by sending JSON
commands over a Unix domain socket to seek and read the playback position.

## License

tucue is released under the [MIT License](LICENSE).

tucue requires [mpv](https://mpv.io/), which is licensed under
GPL-2.0-or-later and LGPL-2.1-or-later. mpv runs as a separate process and
is not distributed with tucue; you install it yourself (e.g. via Homebrew),
so its copyleft terms do not apply to tucue's own source.
