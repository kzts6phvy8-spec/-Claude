# スクショメモ（ScreenMemo）

iPhone の写真に溜まったスクリーンショットを **AI（Google Gemini Flash-Lite）でテキスト化** し、
チャット感覚でメモにできるアプリです。テキスト化した後はスクショを削除して容量を空けられます。

## 🌐 Web アプリ版（おすすめ・Mac 不要）

`docs/` フォルダの Web アプリを GitHub Pages で公開し、iPhone の Safari から使います。

### 使い方

1. 画面右上の ⚙ から **Gemini APIキー** を入力（[Google AI Studio](https://aistudio.google.com/apikey) で無料発行）
2. 左下の画像ボタンからスクリーンショットを選択（複数枚まとめて OK）→ 送信
3. AI が読み取った結果がカードで表示されるので、**「共有」→「メモ」** で iPhone のメモアプリに保存
   （右上の ↑ ボタンで全メモをまとめて書き出しも可能）
4. 「この中で予定だけまとめて」など、チャット欄で続けて質問・整理を依頼できます
5. 保存が終わったら、写真アプリの「スクリーンショット」アルバムで画像を削除
   → 「最近削除した項目」も空にすると容量が空きます

### 読み取り形式（入力欄の上で切り替え）

- **クイズ**（既定）: クイズアプリの対戦画面専用。画面の 30〜72% の範囲（問題文と正解の部分）だけを切り出して AI に送り、
  「問題文（Q）」「正解（A・赤字）」「読み・別解（正解の下の灰色文字）」だけを取り出します。
  プレイヤー名・得点・タイマー・キャラクターは無視。同じ問題は「重複」と表示され、まとめて書き出すときは除外されます。
  クイズ画面でない画像は自動的に通常モードで読み直します。
- **通常**: 画面の文字をすべて書き起こします。

クイズ形式の書き出し例:
```
【1】
Q. 中国戦国時代の政治家・孟嘗君が…意味の四字熟語は何でしょう？
A. 鶏鳴狗盗（けいめいくとう）
```

Safari の共有ボタン →「ホーム画面に追加」で、アプリのように全画面で使えます。

### 公開手順（GitHub Pages）

1. GitHub のリポジトリ → **Settings → General → Danger Zone → Change visibility → Public**
2. **Settings → Pages** → Source: *Deploy from a branch* → Branch: `main`、フォルダ: `/docs` → Save
3. 数分後 `https://<ユーザー名>.github.io/<リポジトリ名>/` で開けます

### セキュリティ・プライバシー

- APIキーは **iPhone のブラウザ内（localStorage）にだけ保存** され、GitHub には一切含まれません。
- 念のため Google Cloud コンソールで APIキーに「HTTP リファラー制限（`https://<ユーザー名>.github.io/*`）」を付けることをおすすめします。
- 画像は Google の Gemini API に送信されます。**無料枠では送信内容が Google のサービス改善に使われる場合があります**。
  パスワードや個人情報が写ったスクショは送らないか、有料枠（課金設定）を利用してください。
- Web アプリはブラウザの制約で写真を直接削除できないため、削除は写真アプリで行ってください。

### 設定できるモデル

既定は `gemini-flash-lite-latest`（常に最新の Flash-Lite）。
動作を固定したい場合は設定画面で `gemini-2.5-flash-lite` などに変更できます。

## 📱 ネイティブ iOS アプリ版（Mac + Xcode が必要）

`ScreenMemo/` に SwiftUI 版があります。写真ライブラリから直接スクショを一覧・一括変換・自動削除でき、
文字認識は端末内（Apple Vision）で行います。

```sh
brew install xcodegen
xcodegen generate
open ScreenMemo.xcodeproj   # Signing の Team を設定して iPhone で実行（iOS 17 以降）
```
