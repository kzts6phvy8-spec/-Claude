import Photos
import UIKit

/// 写真ライブラリから「スクリーンショット」だけを取得・削除する
@MainActor
final class ScreenshotLibrary: ObservableObject {
    @Published private(set) var assets: [PHAsset] = []
    @Published private(set) var status: PHAuthorizationStatus =
        PHPhotoLibrary.authorizationStatus(for: .readWrite)

    var hasAccess: Bool { status == .authorized || status == .limited }

    func requestAccess() async {
        status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        if hasAccess { reload() }
    }

    func reload() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "(mediaSubtypes & %d) != 0",
                                        PHAssetMediaSubtype.photoScreenshot.rawValue)
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var list: [PHAsset] = []
        list.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in list.append(asset) }
        assets = list
    }

    /// OCR 用にフル解像度の画像を読み込む（iCloud 上の画像もダウンロード）
    static func fullImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data.flatMap(UIImage.init(data:)))
            }
        }
    }

    /// グリッド表示用のサムネイル
    static func thumbnail(for asset: PHAsset, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat // コールバックが1回だけになる
            options.resizeMode = .fast
            PHImageManager.default().requestImage(for: asset, targetSize: size,
                                                  contentMode: .aspectFill, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// 削除前に iOS が確認ダイアログを表示する。削除した画像は「最近削除した項目」に移動する。
    func delete(_ targets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChange.deleteAssets(targets as NSArray)
        }
        reload()
    }
}
