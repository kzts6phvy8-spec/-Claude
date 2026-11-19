import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Memo.createdAt, order: .reverse) private var memos: [Memo]
    @State private var searchText = ""
    @State private var showingImport = false

    private var filtered: [Memo] {
        guard !searchText.isEmpty else { return memos }
        return memos.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    /// まとめて「メモ」アプリなどへ送るためのテキスト
    private var exportText: String {
        filtered.map { memo in
            "■ \(memo.displayDate.formatted(date: .numeric, time: .shortened))\n\(memo.text)"
        }.joined(separator: "\n\n")
    }

    var body: some View {
        NavigationStack {
            Group {
                if memos.isEmpty {
                    ContentUnavailableView {
                        Label("メモはまだありません", systemImage: "text.viewfinder")
                    } description: {
                        Text("スクリーンショットを読み込んでテキスト化しましょう")
                    } actions: {
                        Button("スクリーンショットを読み込む") { showingImport = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filtered) { memo in
                            NavigationLink(value: memo) { MemoRow(memo: memo) }
                        }
                        .onDelete { offsets in
                            let targets = offsets.map { filtered[$0] }
                            targets.forEach(context.delete)
                        }
                    }
                    .searchable(text: $searchText, prompt: "テキストを検索")
                }
            }
            .navigationTitle("スクショメモ")
            .navigationDestination(for: Memo.self) { MemoDetailView(memo: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !filtered.isEmpty {
                        ShareLink(item: exportText) {
                            Label("まとめて書き出す", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingImport = true } label: {
                        Label("読み込む", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingImport) { ImportView() }
        }
    }
}

private struct MemoRow: View {
    let memo: Memo

    var body: some View {
        HStack(spacing: 12) {
            if let data = memo.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(memo.title).font(.headline).lineLimit(1)
                Text(memo.text).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Text(memo.displayDate, style: .date).font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}
