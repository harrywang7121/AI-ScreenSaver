import SwiftUI

@main
struct AI_ScreenSaverApp: App {
    @StateObject private var store = SessionStore()

    var body: some Scene {
        WindowGroup("LunchTalk Saver", id: "main") {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 1280, height: 760)

        WindowGroup("Session Summary", id: "summary") {
            SummaryWindowView()
                .environmentObject(store)
        }
        .defaultSize(width: 520, height: 620)
        .windowResizability(.contentSize)
    }
}
