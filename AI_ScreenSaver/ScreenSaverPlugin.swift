import AppKit
import ScreenSaver
import SwiftUI
import Foundation

private enum SaverIPC {
    static let distributedName = "haoyu.LunchTalkSaver.sessionEnded"

    static var summaryFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        let folder = base.appendingPathComponent("LunchTalkSaverIPC", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("last_summary.json")
    }
}

final class LunchTalkScreenSaverView: ScreenSaverView {
    private var hostingView: NSHostingView<AnyView>?
    private var store = SessionStore()

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
        setupHostingView(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 30.0
        setupHostingView(frame: bounds)
    }

    override func startAnimation() {
        super.startAnimation()
        store.restartSession()
    }

    override func stopAnimation() {
        store.endSession()
        publishSessionSummary()
        super.stopAnimation()
    }

    override func animateOneFrame() {
        super.animateOneFrame()
    }

    private func setupHostingView(frame: NSRect) {
        let rootView = SaverContentView(store: store)
        let hostingView = NSHostingView(rootView: AnyView(rootView))
        hostingView.frame = frame
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)
        self.hostingView = hostingView
    }

    private func publishSessionSummary() {
        let s = store.summary
        let payload: [String: Any] = [
            "id": UUID().uuidString,
            "timestamp": Date().timeIntervalSince1970,
            "title": s.title,
            "overview": s.overview,
            "bullets": s.bullets,
            "inspirations": s.inspirations,
            "highlights": s.highlights
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }

        // Reliable IPC: write to shared file.
        try? data.write(to: SaverIPC.summaryFileURL, options: [.atomic])

        // Fast path: also broadcast (may be missed occasionally; file is fallback).
        if let jsonString = String(data: data, encoding: .utf8) {
            DistributedNotificationCenter.default().postNotificationName(
                NSNotification.Name(SaverIPC.distributedName),
                object: jsonString,
                userInfo: nil,
                deliverImmediately: true
            )
        }
    }
}
