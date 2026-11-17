# Nim Clock

[Nim](https://nim-lang.org/) と HTML Canvas で作るブラウザ時計です。既存の [Coffee Clock](https://github.com/naoiw/coffee-clock-view) / [Rust Clock](https://github.com/naoiw/rust-clock-view) と同じデザインと機能を、**NimのJavaScriptバックエンド**で再現します。

## 機能

- 時・分・秒の3本のリングと滑らかな秒表示
- 時刻に応じて変わる色相
- 毎分60個のパーティクルが発生（初回ロードは除外）
- 端末のローカル時刻と日本語の日付（曜日直前のスペースなし）
- スマートフォン / HiDPI / 動きを減らす設定に対応
- 非表示タブでは描画を停止、復帰時に再開

## 公開先

| 環境 | ブランチ | URL |
| --- | --- | --- |
| 本番 | `main` | https://naoiw.github.io/nim-clock-view/ |
| 開発プレビュー | `develop` | https://naoiw.github.io/nim-clock-view/develop/ |

GitHub Pages の **Settings → Pages → Source: GitHub Actions** を選択してください。1つのPages環境で本番とプレビューを別パスに公開します。

## 技術スタック

- **Nim 2.4.2** / JSバックエンド — 時計ロジック、ブラウザCanvas描画、イベント管理
- **std/jsffi** — DOM、Canvas、requestAnimationFrame とNimの相互運用
- **HTML / CSS** — 画面構造、レスポンシブスタイル
- **GitHub Actions / Pages** — 品質チェックと自動公開
- 外部NimパッケージやNode.jsランタイムへの依存はありません。

## ローカル開発

Nim 2.4.2 とPython 3、シェル環境を用意します。

```bash
nim c -r tests/test_clock_math.nim
bash scripts/build.sh
# Node.jsをお持ちの場合はJSの動作検証も可能
node tests/browser-smoke.cjs
python3 -m http.server 3000
```

ブラウザで http://localhost:3000/ を開きます。コードを変更したら `bash scripts/build.sh` を実行します。生成物の `dist/` は Git 管理しません。

## ブランチ運用

1. 機能開発は `develop` をベースに進め、`main` は本番のみに使用します。
2. `develop` 宛／`main` 宛PRではNim単体テストとJavaScriptビルドを実行します。
3. `develop` のpush後、CIに成功すると `/develop/` にプレビューが公開されます。
4. 本番反映は `develop` → `main` のPRで行います。マージ後も `develop` を維持します。

## 構成

- `src/clock_math.nim` — テスト可能な時計計算、描画位置、パーティクル状態更新
- `src/clock.nim` — JS相互運用、Canvas描画、描画ループ、ブラウザイベント
- `src/styles.css` — 画面スタイル
- `tests/test_clock_math.nim` — Nim標準 `unittest` による単体テスト
- `tests/browser-smoke.cjs` — 生成JavaScriptの起動・描画スモークテスト（CI用）
- `scripts/build.sh` — `nim js` と静的ファイルのビルド
- `index.html` — HTMLエントリポイント
- `.github/workflows/` — CIとPagesデプロイ
- `docs/architecture.md` — 構成と設計の詳細

## ドキュメント

- [設計・デプロイ構成](docs/architecture.md)

## ライセンス

[MIT License](LICENSE)
