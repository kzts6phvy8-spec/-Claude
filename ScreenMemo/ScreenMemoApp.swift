import SwiftUI
import SwiftData

@main
struct ScreenMemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Memo.self)
    }
}
