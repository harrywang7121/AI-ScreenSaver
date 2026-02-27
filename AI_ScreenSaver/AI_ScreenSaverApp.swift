import SwiftUI
import AppKit
import Combine

// Internal bridge: DistributedNotificationCenter → SwiftUI
extension Notification.Name {
    static let saverDidEnd = Notification.Name("haoyu.LunchTalkSaver.saverDidEndInternal")
}

@main
struct AI_ScreenSaverApp: App {
    @StateObject private var store = SessionStore()
    // Keeps the distributed-notification bridge alive for the app's lifetime
    @StateObject private var bridge = SaverNotificationBridge()

    var body: some Scene {
        WindowGroup("LunchTalk Saver", id: "main") {
            ContentView(mode: .main)
                .environmentObject(store)
                .environmentObject(bridge)
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

/// Listens for the DistributedNotificationCenter broadcast from the .saver bundle,
/// decodes the session summary JSON, and re-broadcasts internally so the SwiftUI
/// ContentView can react (via onChange on eventCount) and call openWindow(id: "summary").
final class SaverNotificationBridge: ObservableObject {
    /// Increments every time a new saver session ends — used as Equatable trigger in onChange.
    @Published var eventCount: Int = 0
    /// The latest decoded summary payload; read after eventCount fires.
    private(set) var latestPayload: [String: Any]? = nil

    private var cancellables = Set<AnyCancellable>()

    init() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("haoyu.LunchTalkSaver.sessionEnded"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let jsonString = notification.object as? String,
                let data = jsonString.data(using: .utf8),
                let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return }

            self?.latestPayload = payload
            self?.eventCount += 1          // triggers onChange in ContentView
        }
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
    }
}
