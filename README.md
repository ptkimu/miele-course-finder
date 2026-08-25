# ミエーレ コース診断（LIFF マッチングツール）

ビューティサロン **ミエーレ**（茨城県古河市／古河駅 徒歩8分）向けの、条件フィルタリング型コース診断ツール。
LINE公式アカウント内の **LIFF** で開くことを想定した、スマホ縦画面最適化の1ファイル完結プロトタイプ。

診断は3ステップのみ。性格タイプ診断のような要素は入れず、条件の一致数で候補を絞り込む。

1. **お悩み**（複数選択・10項目）
2. **予算**（5択）
3. **通い方**（4択）

→ 上位3件のコースを「一致度％」と「一致した条件タグ」つきで提示 → LINEトークへ相談内容を自動送信。

---

## ファイル構成

| パス | 役割 |
|---|---|
| `index.html` | **本体（これが編集対象）**。LIFF SDK 読み込み込みの単体HTML。依存パッケージなし |
| `out/index.html` | Netlify Drop 用の配布コピー。`build.sh` で `index.html` から生成 |
| `out/robots.txt` | テスト公開用の noindex 設定 |
| `core.html` | Artifactプレビュー用に `<head>` を剥いだ版。`build.sh` で生成 |
| `build.sh` | `index.html` → `out/` と `core.html` を生成 |
| `serve.ps1` | ローカル確認用の静的サーバー（http://localhost:8080/） |

`index.html` を直接編集し、`bash build.sh` で他を再生成する。逆方向の生成はしない。

---

## ローカルで確認する

```bash
# そのままブラウザで開くだけでも全機能動く
start index.html

# もしくはローカルサーバー
powershell -ExecutionPolicy Bypass -File serve.ps1   # → http://localhost:8080/
```

Chrome の `Ctrl+Shift+M`（デバイスツールバー）でスマホ縦画面を再現できる。

---

## マッチングロジック

`index.html` 内の `scoreCourse()`。加点方式でスコアリングし、降順で上位3件を返す。

| 条件 | 加点 |
|---|---|
| お悩みタグの一致 | 1つにつき **+2** |
| 予算がぴったりの価格帯 | **+3** |
| 予算が隣の価格帯 | **+1** |
| 予算「こだわらない」 | **+2** |
| 通い方の一致 | **+3** |

- 一致率 = スコア ÷ 満点（`選択した悩み数×2 + 3 + 3`）
- **お悩みが1つも一致しないコースは結果に出さない**（`getResults()` のフィルタ）。条件フィルタリングとしての筋を通すため
- 価格帯の判定は `tierOf()`。境界は 5,500 / 10,000 / 15,000 円

### 価格の扱い

コースは `price`（通常価格）と `camp`（キャンペーン価格・任意）を持つ。
**予算判定・並び順・LINE送信文はすべて `payPrice()` = 実際に支払う金額（`camp` があればそちら）で計算する。**
通常価格のみで判定すると、キャンペーンで安くなっているコースが低予算のユーザーに出なくなるため。

結果カードでは `¥4,950 ~~¥6,600~~` のように二段表示し、「キャンペーン価格」バッジを出す。

---

## データを更新する

すべて `index.html` の先頭付近の配列を書き換えるだけ。

- `CONCERNS` — お悩みの選択肢（`id` / `label` / `em`）
- `BUDGETS` — 予算の選択肢（`tier` が `tierOf()` の戻り値と対応。`tier:0` は「こだわらない」）
- `PACES` — 通い方の選択肢
- `COURSES` — コース一覧

```js
{
  name:'韓国肌管理 ダクトピール',   // コース名
  price:7800,                      // 通常価格（税込）
  camp:null,                       // キャンペーン価格（任意）
  min:null,                        // 所要時間（分）。不明なら null で非表示
  cat:'韓国肌管理',                // カテゴリ表示
  badge:'新規限定',                // バッジ文言（空文字で非表示）
  concerns:['pore','acne'],        // CONCERNS の id
  paces:['monthly','intensive'],   // PACES の id
  desc:'…'                         // 説明文
}
```

`concerns` / `paces` に書く id は必ず `CONCERNS` / `PACES` に存在するものを使う（タイプミスすると永久に候補に出てこない）。

現在のデータ元は HOT PEPPER Beauty 掲載分（36コース）。
https://beauty.hotpepper.jp/kr/slnH000649391/coupon/

> 注意：サロントップページとメニューページで脱毛の価格が異なる。トップ側がキャンペーン価格という整理で、
> `camp` フィールドに入れてある。60分メニューと全身脱毛は通常価格が未確認のため、バッジ表示のみ。

---

## Netlify Drop でテスト公開する

1. `bash build.sh` で `out/` を最新化
2. https://app.netlify.com/drop に `out` フォルダをドラッグ&ドロップ
3. 発行されたURLをスタッフに共有

この状態では `LIFF_ID` が未設定なので、相談ボタンは **プレビューモード**（送信内容を `alert` で表示）で動く。
画面下部に「テスト版（LINE連携は未接続）」と表示される。

---

## LIFF に接続する

1. [LINE Developers](https://developers.line.biz/console/) でプロバイダー → LINEログインチャネル → **LIFFアプリ**を作成
   - Size: **Full**
   - Scope: **profile** / **chat_message.write**
   - エンドポイントURL: Netlify や Vercel で発行されたHTTPS URL
2. `index.html` 冒頭の `LIFF_ID` を発行されたIDに差し替え

```js
var LIFF_ID = 'xxxxxxxxxx-xxxxxxxx';   // ← ここ
```

3. 再デプロイ
4. LINE公式アカウントのリッチメニューに `https://liff.line.me/＜LIFF_ID＞` を設定

### 実装済みの挙動

| 関数 | 動作 |
|---|---|
| `initLiff()` | `liff.init()` → `getProfile()`。Q1の見出しが「〇〇さん、いま気になる…」になる |
| `sendToLine()` | `liff.sendMessages()` で条件＋コース名を送信 → トースト表示 → `liff.closeWindow()` |

- LIFF外／ID未設定なら自動でプレビューモード（`alert`）に落ちるので、デプロイ前でも動作確認できる
- 外部ブラウザで開かれた場合は `liff.login()` に誘導
- 送信失敗時はトーストでリトライ案内

`liff.init()` と `sendMessages()` は **HTTPSの公開URL** でしか動かない。localhost では常にプレビューモードになる。

---

## 動作確認のしかた（Node不要）

このリポジトリは依存パッケージゼロ。JSの構文チェックはWindows標準のJScriptエンジンでできる。

```powershell
$src = Get-Content -Raw -Encoding UTF8 index.html
$js  = (($src -split '<script>')[1] -split '</script>')[0]
# .catch( はES3予約語でJScriptが誤検出するため置換
$probe = "function __probe(){`r`n" + $js.Replace('.catch(','.qatch(') + "`r`n}`r`nWScript.Echo('OK');"
[IO.File]::WriteAllText("$env:TEMP\probe.js", $probe, [Text.Encoding]::Unicode)
cscript //Nologo //E:JScript "$env:TEMP\probe.js"
```
