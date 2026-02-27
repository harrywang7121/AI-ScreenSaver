import SwiftUI
import AppKit
import Combine
import Foundation

@main
struct AI_ScreenSaverApp: App {
    @StateObject private var store = SessionStore()
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

private enum SaverIPC {
    static let distributedName = "haoyu.LunchTalkSaver.sessionEnded"
    static let consumedIDKey = "lastConsumedSaverSummaryID"

    // Use /tmp for cross-process reliability between ScreenSaverEngine and app.
    static var summaryFileURL: URL {
        let folder = URL(fileURLWithPath: "/tmp/LunchTalkSaverIPC", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("last_summary.json")
    }

    // Legacy path (older builds wrote here). Keep for backward compatibility.
    static var legacySummaryFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        return base.appendingPathComponent("LunchTalkSaverIPC/last_summary.json")
    }
}

/// Bridge from .saver (separate process) to app UI:
/// 1) consume distributed notification (fast path)
/// 2) poll shared file `last_summary.json` (reliable fallback)
final class SaverNotificationBridge: ObservableObject {
    @Published var eventCount: Int = 0
    private(set) var latestPayload: [String: Any]? = nil

    private var timer: Timer?
    private var summaryWindow: NSWindow?

    init() {
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(SaverIPC.distributedName),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let jsonString = notification.object as? String,
                let data = jsonString.data(using: .utf8),
                let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return }
            self?.consumeIfNew(payload)
        }

        // Reliable fallback in case distributed notification is missed.
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollSummaryFile()
        }
        RunLoop.main.add(timer!, forMode: .common)

        // Read once on startup too.
        pollSummaryFile()
    }

    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
        timer?.invalidate()
    }

    private func pollSummaryFile() {
        let urls = [SaverIPC.summaryFileURL, SaverIPC.legacySummaryFileURL]
        for url in urls {
            guard let data = try? Data(contentsOf: url),
                  let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { continue }
            consumeIfNew(payload)
            return
        }
    }

    private func consumeIfNew(_ payload: [String: Any]) {
        guard let id = payload["id"] as? String else { return }
        let last = UserDefaults.standard.string(forKey: SaverIPC.consumedIDKey)
        guard id != last else { return }

        latestPayload = payload
        eventCount += 1
        UserDefaults.standard.set(id, forKey: SaverIPC.consumedIDKey)

        let showPopup = UserDefaults.standard.object(forKey: "showPopupOnExit") as? Bool ?? true
        if showPopup {
            Task { @MainActor in
                showSummaryWindow(payload)
            }
        }
    }

    @MainActor
    private func showSummaryWindow(_ payload: [String: Any]) {
        let view = BridgeSummaryView(payload: payload)
        let hosting = NSHostingController(rootView: view)

        let window = NSWindow(contentViewController: hosting)
        window.title = "Session Summary"
        window.setContentSize(NSSize(width: 520, height: 620))
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        summaryWindow = window
    }
}

private struct BridgeSummaryView: View {
    let payload: [String: Any]

    private var title: String { payload["title"] as? String ?? "Session Summary" }
    private var overview: String { payload["overview"] as? String ?? "" }
    private var bullets: [String] { payload["bullets"] as? [String] ?? [] }
    private var inspirations: [String] { payload["inspirations"] as? [String] ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title3).bold()
            if !overview.isEmpty { Text(overview).foregroundStyle(.secondary) }

            if !bullets.isEmpty {
                Text("摘要").font(.headline)
                ForEach(bullets, id: \.self) { Text("• \($0)") }
            }
            if !inspirations.isEmpty {
                Text("灵感点").font(.headline)
                ForEach(inspirations, id: \.self) { Text("• \($0)") }
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
