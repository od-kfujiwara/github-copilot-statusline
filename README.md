# github-copilot-statusline
GitHub Copilot CLI の statusline に、Premium Requests の消費状況と消費ペースガイドを表示するカスタム statusline です。

「今月あとどれくらい使ってよさそうか」を CLI 上でざっくり把握できるようにします。

```text
⚡ █░░░░░░░░░░░ 36/300 (12.0%) │ 26d left │ pace guide:10 req/day │ CHILL
````

## Features
* 割り当てられた AI credits の使用量を statusline に表示
* 使用済み AI credits と使用率を表示
* 次回リセット日までの残り日数を表示
* 残りの AI credits 数から 1 日あたりの目安消費量を表示
* 消費ペースに応じて `CHILL` / `CAUTION` / `DANGER` を色付きで表示

## Display example

```text
⚡ ███░░░░░░░░░ 360/3000 (12.0%) │ 26d left │ pace guide:10 credits/day │ CHILL
```

| 表示                      | 内容                    |
| ----------------------- | --------------------- |
| `360/3000`                | 使用済み AI credits 数 / 割り当てられた月間上限     |
| `12.0%`                 | 使用率                   |
| `26d left`              | 次回リセット日までの残り日数        |
| `pace guide:10 credis/day` | 月末まで均等に使う場合の 1 日あたり目安 |
| `CHILL / CAUTION / DANGER` | 消費ペースステータス     |

## Requirements

* GitHub Copilot CLI
* Python 3
* Bash
* GitHub Copilot CLI の experimental features が有効であること

## Installation

### 1. Clone this repository

```bash
git clone https://github.com/<OWNER>/<REPO>.git
cd <REPO>
```

### 2. Copy files to `~/.copilot`

```bash
mkdir -p ~/.copilot/extensions/premium-quota

cp statusline.sh ~/.copilot/statusline.sh
cp extensions/premium-quota/extension.mjs ~/.copilot/extensions/premium-quota/extension.mjs

chmod u+x ~/.copilot/statusline.sh
```

配置後のイメージは以下です。

```text
~/.copilot/
├── settings.json
├── statusline.sh
└── extensions/
    └── premium-quota/
        └── extension.mjs
```

### 3. Update `~/.copilot/settings.json`

`~/.copilot/settings.json` に以下の設定を追加してください。

```json
{
  "experimental": true,
  "statusLine": {
    "type": "command",
    "command": "~/.copilot/statusline.sh",
    "padding": 0
  }
}
```

### 4. Start GitHub Copilot CLI

```bash
copilot
```

Copilot CLI 上で `/env` を実行し、`premium-quota` extension が読み込まれているか確認します。

```text
/env
```

Extensions に `premium-quota` が表示されていれば OK です。

### 5. Enable custom statusline

Copilot CLI 上で `/statusline` を実行します。

```text
/statusline
```

`custom` を ON にしてください。

最後に Copilot CLI を再起動します。

```text
/restart
```

再起動後、Copilot CLI で一度チャットを送信すると、statusline に Premium Requests の消費状況が表示されます。

## Pacing status

| Status    | 条件               | 意味     |
| --------- | ---------------- | ------ |
| `CHILL`   | 実際の消費ペースが理想ペース以下 | いいペース  |
| `CAUTION` | 理想ペースの 1.4 倍以内   | 少し早め   |
| `DANGER`  | 理想ペースの 1.4 倍超え   | 使いすぎ注意 |

判定は `statusline.sh` 内の `WARNING_PACE_RATIO` で調整できます。

```python
WARNING_PACE_RATIO = 1.4
```

## Related article
zennで記事を公開しています。
* [GitHub Copilotの使いすぎを防ぐ、消費ペースガイド付きstatuslineを作ってみた](https://zenn.dev/gyory/articles/1bd42b8f9d7fbc)
