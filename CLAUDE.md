# tucue

## プロジェクト概要

ローカル音声ファイルを再生しながら、特定の時間をマークしてエクスポートできる Ruby 製 TUI アプリケーション。

- **gem名**: `tucue`（TUI + Cue の合成語、発音：トゥキュー）
- **RubyGems登録**: 予定あり（名前の空きは rubygems.org で要確認）

---

## 機能要件

- [ ] mp3 / wav ファイルの再生
- [ ] 5秒・15秒単位の巻き戻し・早送り
- [ ] 現在時刻のマーク登録（任意ラベル付き）
- [ ] マーク一覧のファイルエクスポート（CSV / JSON）

---

## 技術方針

### 音声再生エンジン
- **mpv** に委譲する（`brew install mpv` が前提）
- `--input-ipc-server` でUnixソケットを開き、RubyからJSONコマンドを送信して制御する

```bash
mpv --input-ipc-server=/tmp/tucue.sock target.mp3
```

```ruby
# シーク例
socket.puts({ command: ["seek", 15, "relative"] }.to_json)
socket.puts({ command: ["seek", -5, "relative"] }.to_json)

# 現在位置取得
socket.puts({ command: ["get_property", "time-pos"] }.to_json)
```

### TUI
- **curses**（Ruby標準添付）をベースに実装
- 必要に応じて **tty-\* シリーズ**（`tty-cursor`, `tty-screen`, `tty-box`）を併用

### スレッド構成
- メインスレッド: curses のキー入力ループ
- サブスレッド: mpv の再生位置をポーリングして画面を更新

### エクスポート形式
- CSV（デフォルト）
- JSON（オプション）

---

## UI イメージ

```
┌─────────────────────────────────┐
│  ファイル: interview.mp3         │
│  00:01:23 / 00:45:10  ████░░░░  │
├─────────────────────────────────┤
│  [Space] 再生/停止               │
│  [←] -5s  [→] +5s              │
│  [[] -15s  []] +15s            │
│  [m] マーク  [e] エクスポート    │
│  [q] 終了                       │
├─────────────────────────────────┤
│  マーク一覧                      │
│  * 00:01:23 - ここ重要           │
│  * 00:03:45 -                   │
└─────────────────────────────────┘
```

---

## キーバインド

| キー | 動作 |
|---|---|
| `Space` | 再生 / 一時停止 |
| `→` | +5秒 |
| `←` | -5秒 |
| `]` | +15秒 |
| `[` | -15秒 |
| `m` | 現在位置をマーク |
| `e` | マークをエクスポート |
| `q` | 終了 |

---

## 想定するgem構成

```
tucue/
├── CLAUDE.md
├── tucue.gemspec
├── Gemfile
├── bin/
│   └── tucue          # エントリポイント（CLIコマンド）
└── lib/
    └── tucue/
        ├── version.rb
        ├── player.rb  # mpv制御
        ├── ui.rb      # curses TUI
        └── marker.rb  # マーク管理・エクスポート
```

---

## 使用イメージ

```bash
tucue interview.mp3
```

---

## 環境・前提条件

- macOS（開発者環境）
- Ruby（バージョン指定なし、3.x系推奨）
- mpv（`brew install mpv` でインストール）
- 開発ディレクトリ: `~/tucue/`（このファイルと同階層で `bundle exec` する想定）
