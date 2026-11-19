import Foundation
import SwiftData

/// スクリーンショットから抽出したテキストを1件のメモとして保存する
@Model
final class Memo {
    var text: String
    var createdAt: Date
    /// 元のスクリーンショットの撮影日時
    var screenshotDate: Date?
    /// 元画像の PHAsset.localIdentifier（変換済み判定に使う）
    var assetIdentifier: String?
    /// 元画像を削除しても内容を思い出せるよう、小さなサムネイルを残す
    @Attribute(.externalStorage) var thumbnailData: Data?

    init(text: String,
         createdAt: Date = .now,
         screenshotDate: Date? = nil,
         assetIdentifier: String? = nil,
         thumbnailData: Data? = nil) {
        self.text = text
        self.createdAt = createdAt
        self.screenshotDate = screenshotDate
        self.assetIdentifier = assetIdentifier
        self.thumbnailData = thumbnailData
    }

    /// 1行目をタイトルとして使う
    var title: String {
        let firstLine = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { !$0.isEmpty }
        return firstLine.map(String.init) ?? "（空のメモ）"
    }

    var displayDate: Date { screenshotDate ?? createdAt }
}
