# 設計メモ

## 方針

[Coffee Clock](https://github.com/naoiw/coffee-clock-view) と [Rust Clock](https://github.com/naoiw/rust-clock-view) の3リング時計と操作感をNimで再現します。Nimの **JavaScriptバックエンド**で出力した `dist/clock.js` をブラウザで直接実行します。WebAssemblyは使用せず、手書きJavaScriptも必要ありません。Nim 2.4.2をCIで固定し、外部Nimパッケージは使用しません。

```text
index.html                 ルートエントリ
src/clock_math.nim         計算・フォーマット・粒子更新（純粋なNim）
src/clock.nim              DOM/Canvas FFI・描画・ブラウザの描画ループ
src/styles.css             Coffee Clockと同じスタイル
tests/test_clock_math.nim  Nim標準unittestによるネイティブテスト
scripts/build.sh           JS生成とCSSコピー
dist/                      生成物（Git管理対象外）
.github/workflows/         CIとPagesデプロイ
```

## 時計

- 日付と時刻はブラウザ端末のローカルタイム（JavaScriptの `Date`）です。
- 日本語日付は `2026年11月17日火曜日` のように曜日前のスペースを入れず、他のClockと統一します。
- 時・分・秒はミリ秒を含む進捗率で3つのリングをCanvasに描きます。
- 時間と分に応じた色相、毎分の切替で60個の粒子、秒を示す小さな点を表示します。
- 初回表示では粒子を発生させません。粒子寿命と移動に経過時間を使用し、経過差分は50ms上限です。
- Canvasの内部解像度は `devicePixelRatio` の最大2倍、描画はCSSピクセルに換算します。
- タブが非表示の間は `requestAnimationFrame` を停止し、表示時に前フレームの経過時刻をリセットします。
- `prefers-reduced-motion` 有効時は粒子・残像を消し、秒リングは秒単位で進みます。

## Nim とブラウザの連携

`src/clock.nim` はNimの標準 `std/jsffi` と `importjs` を使い、DOM、Canvas 2D、JavaScript Date、`requestAnimationFrame` の最小限の呼び出しだけ定義します。時刻・図形計算は `clock_math.nim` に分離し、`nim c -r tests/test_clock_math.nim` でブラウザなしに検証します。

## ビルドとCI

`bash scripts/build.sh` は `nim js -d:release --out:dist/clock.js src/clock.nim` を実行します。Nim標準のみで動作し、npmやNimbleパッケージのインストールは不要です。Node.jsは実行環境に不要です。

- `validate-develop.yml`：develop push、main/develop宛PRに対して単体テストとJSビルドを実行。PRはデプロイしません。
- `deploy-pages.yml`：main push、成功したdevelop pushのCI完了後に本番・プレビューをビルドして1つのPagesアーティファクトを公開します。
- `workflow_run` ではCI済みdevelopコミットSHAをcheckoutします。検証失敗・PR完了イベントからは公開しません。
- 本番 `/nim-clock-view/`、プレビュー `/nim-clock-view/develop/`。両方の `index.html` と `dist` を独立した相対パスで配置します。

GitHub Settings → Pages → Source は GitHub Actions です。既定ブランチmain上にデプロイワークフローを置く必要があります。

## 変更時の品質確認

```bash
nim c -r tests/test_clock_math.nim
bash scripts/build.sh
```

実行時のCanvas API呼び出しについては、必要に応じてブラウザ開発者ツールで確認してください。
