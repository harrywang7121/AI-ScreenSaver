import SwiftUI

@main
struct AI_ScreenSaverApp: App {
    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup("LunchTalk Saver", id: "main") {
            ContentView(mode: .main)
                .environmentObject(store)
        }
        .defaultSize(width: 1280, height: 760)

        WindowGroup("LunchTalk Saver (Screen Saver)", id: "saver") {
            SaverWindowView()
                .environmentObject(store)
        }
        .defaultSize(width: 1280, height: 760)
        .windowResizability(.contentSize)

        WindowGroup("Session Summary", id: "summary") {
            SummaryWindowView()
                .environmentObject(store)
        }
        .defaultSize(width: 520, height: 620)
        .windowResizability(.contentSize)

        WindowGroup("Session History", id: "history") {
            HistoryView()
                .environmentObject(store)
        }
        .defaultSize(width: 980, height: 720)
    }
}
