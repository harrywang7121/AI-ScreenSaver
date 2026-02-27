import AppKit
import ScreenSaver
import SwiftUI
import Foundation

private enum SaverIPC {
    static let distributedName = "haoyu.LunchTalkSaver.sessionEnded"

    static var ipcFolders: [URL] {
        [
            URL(fileURLWithPath: "/tmp/LunchTalkSaverIPC", isDirectory: true),
            URL(fileURLWithPath: "/Users/Shared/LunchTalkSaverIPC", isDirectory: true)
        ]
    }

    static var summaryFileURLs: [URL] {
        ipcFolders.map { folder in
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            return folder.appendingPathComponent("last_summary.json")
        }
    }

    static var heartbeatURLs: [URL] {
        ipcFolders.map { folder in
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            return folder.appendingPathComponent("heartbeat.txt")
        }
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
        writeHeartbeat("startAnimation at \(Date())")
        store.restartSession()
    }

    override func stopAnimation() {
        store.endSession()
        writeHeartbeat("stopAnimation at \(Date())")
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

    private func writeHeartbeat(_ text: String) {
        let line = "\(text)\n"
        guard let data = line.data(using: .utf8) else { return }
        for url in SaverIPC.heartbeatURLs {
            if FileManager.default.fileExists(atPath: url.path),
               let handle = try? FileHandle(forWritingTo: url) {
                try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                try? handle.close()
            } else {
                try? data.write(to: url, options: [.atomic])
            }
        }
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

        // Reliable IPC: write to shared files (multiple locations for robustness).
        for url in SaverIPC.summaryFileURLs {
            try? data.write(to: url, options: [.atomic])
        }

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
