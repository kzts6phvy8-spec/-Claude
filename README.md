# スクショメモ（ScreenMemo）

iPhone の写真に溜まったスクリーンショットを **AI で文字認識（OCR）してテキスト化** し、
メモとして保存・検索・書き出しできる iOS アプリです。テキスト化した後は元のスクリーンショットを削除して容量を空けられます。

## 主な機能

- 写真ライブラリから **スクリーンショットだけ** を一覧表示（変換済みには「変換済み」バッジ）
- 「未変換を全選択」でまとめてテキスト化
- Apple の Vision フレームワークによる **端末内 AI 文字認識**（日本語・英語対応、外部送信なし・無料）
- テキストはアプリ内にメモとして保存（全文検索・編集・コピー・小さなサムネイル付き）
- 共有ボタンから **Apple の「メモ」アプリ** などに送信（1件ずつ / まとめて）
- 「変換後にスクリーンショットを削除」をオンにすると、テキスト化に成功した画像だけを削除
  （文字が見つからなかった画像は削除しません）

> ⚠️ 削除した画像は写真アプリの「最近削除した項目」に30日間残ります。すぐに容量を空けたい場合はそこも空にしてください。

> ℹ️ Apple の「メモ」アプリには他アプリから直接書き込む公開 API がないため、共有シート経由で保存します。

## ビルド方法（Mac が必要）

1. Mac に Xcode 15 以降と [XcodeGen](https://github.com/yonaskolb/XcodeGen) をインストール
   ```sh
   brew install xcodegen
   ```
2. このリポジトリで Xcode プロジェクトを生成して開く
   ```sh
   xcodegen generate
   open ScreenMemo.xcodeproj
   ```
3. Xcode で `ScreenMemo` ターゲット → Signing & Capabilities → Team に自分の Apple ID を設定
   （`PRODUCT_BUNDLE_IDENTIFIER` の `com.example.screenmemo` は自分用の一意な ID に変更）
4. iPhone を Mac に接続して実行（無料の Apple ID でも自分の iPhone にインストール可能。
   その場合 7 日ごとに再インストールが必要です）

要件: iOS 17 以降

## 構成

```
ScreenMemo/
├── ScreenMemoApp.swift          アプリのエントリポイント（SwiftData）
├── Models/Memo.swift            メモのデータモデル
├── Services/OCRService.swift    Vision による文字認識
├── Services/ScreenshotLibrary.swift  スクリーンショットの取得・削除
└── Views/
    ├── ContentView.swift        メモ一覧・検索・まとめて書き出し
    ├── ImportView.swift         スクリーンショット選択・テキスト化
    └── MemoDetailView.swift     メモの編集・コピー・共有
```

## Mac がない場合：「ショートカット」アプリで同じことをする

iPhone 標準の「ショートカット」アプリでも、簡易版を作れます。

1. 「写真を検索」— フィルタ: *スクリーンショットである*、並び順: 作成日（新しい順）、制限: 例 20 枚
2. 「各項目を反復」
   - 「画像からテキストを抽出」（入力: 反復項目）
   - 「メモを作成」（本文: 抽出したテキスト）
3. 反復の終了後に「写真を削除」（入力: 写真）※確認が表示されます
