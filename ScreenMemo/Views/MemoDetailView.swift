import SwiftUI

struct MemoDetailView: View {
    @Bindable var memo: Memo
    @State private var copied = false
    @State private var showingImage = false

    var body: some View {
        TextEditor(text: $memo.text)
            .padding(.horizontal)
            .navigationTitle(memo.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if memo.thumbnailData != nil {
                        Button { showingImage = true } label: {
                            Label("元画像", systemImage: "photo")
                        }
                    }
                    Button {
                        UIPasteboard.general.string = memo.text
                        copied = true
                    } label: {
                        Label("コピー", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    // 共有シートから「メモ」アプリを選ぶと Apple のメモに保存できる
                    ShareLink(item: memo.text)
                }
            }
            .sheet(isPresented: $showingImage) {
                if let data = memo.thumbnailData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .presentationDetents([.large])
                }
            }
    }
}
