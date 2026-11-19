import SwiftUI
import SwiftData
import Photos

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var memos: [Memo]
    @StateObject private var library = ScreenshotLibrary()

    @State private var selected: Set<String> = []
    @AppStorage("deleteAfterConvert") private var deleteAfter = false
    @State private var isProcessing = false
    @State private var progress = 0
    @State private var total = 0
    @State private var resultMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]

    private var convertedIDs: Set<String> { Set(memos.compactMap(\.assetIdentifier)) }
    private var unconverted: [PHAsset] {
        library.assets.filter { !convertedIDs.contains($0.localIdentifier) }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("スクリーンショット")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { dismiss() }.disabled(isProcessing)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        if library.hasAccess && !unconverted.isEmpty {
                            Button(selected.isEmpty ? "未変換を全選択" : "選択解除") {
                                if selected.isEmpty {
                                    selected = Set(unconverted.map(\.localIdentifier))
                                } else {
                                    selected.removeAll()
                                }
                            }
                            .disabled(isProcessing)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if library.hasAccess { bottomBar }
                }
                .overlay { if isProcessing { progressCard } }
                .interactiveDismissDisabled(isProcessing)
                .alert("完了", isPresented: Binding(
                    get: { resultMessage != nil },
                    set: { if !$0 { resultMessage = nil } })) {
                    Button("OK") { resultMessage = nil }
                } message: {
                    Text(resultMessage ?? "")
                }
                .task { await library.requestAccess() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch library.status {
        case .authorized, .limited:
            if library.assets.isEmpty {
                ContentUnavailableView("スクリーンショットがありません", systemImage: "photo.on.rectangle")
            } else {
                ScrollView {
                    Text("\(library.assets.count)枚（未変換 \(unconverted.count)枚）")
                        .font(.footnote).foregroundStyle(.secondary).padding(.top, 8)
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(library.assets, id: \.localIdentifier) { asset in
                            cell(for: asset)
                        }
                    }
                }
            }
        case .notDetermined:
            ProgressView()
        default:
            ContentUnavailableView {
                Label("写真へのアクセスが必要です", systemImage: "lock")
            } description: {
                Text("設定アプリで写真へのアクセスを「フルアクセス」にしてください")
            } actions: {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    private func cell(for asset: PHAsset) -> some View {
        let id = asset.localIdentifier
        let isSelected = selected.contains(id)
        let isConverted = convertedIDs.contains(id)
        return AssetThumbnail(asset: asset)
            .overlay(alignment: .topTrailing) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .white)
                    .shadow(radius: 2)
                    .padding(6)
            }
            .overlay(alignment: .bottomLeading) {
                if isConverted {
                    Text("変換済み")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.green, in: Capsule())
                        .foregroundStyle(.white)
                        .padding(6)
                }
            }
            .opacity(isConverted && !isSelected ? 0.6 : 1)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isProcessing else { return }
                if isSelected { selected.remove(id) } else { selected.insert(id) }
            }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Toggle("変換後にスクリーンショットを削除", isOn: $deleteAfter)
                .font(.subheadline)
            Button {
                Task { await process() }
            } label: {
                Text("テキスト化する（\(selected.count)枚）")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selected.isEmpty || isProcessing)
        }
        .padding()
        .background(.bar)
    }

    private var progressCard: some View {
        VStack(spacing: 12) {
            ProgressView(value: Double(progress), total: Double(max(total, 1)))
            Text("文字を認識しています… \(progress) / \(total)")
                .font(.subheadline)
        }
        .padding(24)
        .frame(maxWidth: 280)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - 変換処理

    private func process() async {
        let targets = library.assets.filter { selected.contains($0.localIdentifier) }
        guard !targets.isEmpty else { return }

        isProcessing = true
        total = targets.count
        progress = 0

        var converted: [PHAsset] = []
        var emptyCount = 0
        var failedCount = 0

        for asset in targets {
            defer { progress += 1 }
            guard let image = await ScreenshotLibrary.fullImage(for: asset),
                  let cgImage = image.cgImage else {
                failedCount += 1
                continue
            }
            do {
                let text = try await OCRService.recognizeText(in: cgImage)
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    emptyCount += 1 // 文字のない画像は削除対象にしない
                    continue
                }
                // 同じ画像を再変換した場合は既存メモを置き換える
                if let existing = memos.first(where: { $0.assetIdentifier == asset.localIdentifier }) {
                    context.delete(existing)
                }
                context.insert(Memo(
                    text: text,
                    screenshotDate: asset.creationDate,
                    assetIdentifier: asset.localIdentifier,
                    thumbnailData: makeThumbnail(image)))
                converted.append(asset)
            } catch {
                failedCount += 1
            }
        }
        try? context.save()

        var lines = ["\(converted.count)枚をテキスト化しました。"]
        if emptyCount > 0 { lines.append("文字が見つからなかった画像: \(emptyCount)枚") }
        if failedCount > 0 { lines.append("読み込めなかった画像: \(failedCount)枚") }

        if deleteAfter && !converted.isEmpty {
            do {
                try await library.delete(converted)
                lines.append("\(converted.count)枚を削除しました。容量を空けるには写真アプリの「最近削除した項目」も空にしてください。")
            } catch {
                lines.append("画像の削除はキャンセルされました。")
            }
        }

        selected.removeAll()
        isProcessing = false
        resultMessage = lines.joined(separator: "\n")
    }

    private func makeThumbnail(_ image: UIImage) -> Data? {
        let width: CGFloat = 400
        let height = width * image.size.height / max(image.size.width, 1)
        return image.preparingThumbnail(of: CGSize(width: width, height: height))?
            .jpegData(compressionQuality: 0.6)
    }
}

private struct AssetThumbnail: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        Color(.secondarySystemBackground)
            .aspectRatio(0.5, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            }
            .clipped()
            .task(id: asset.localIdentifier) {
                image = await ScreenshotLibrary.thumbnail(for: asset, size: CGSize(width: 240, height: 480))
            }
    }
}
