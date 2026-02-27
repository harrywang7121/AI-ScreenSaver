import AppKit
import ScreenSaver
import SwiftUI

/// Notification name used to signal the companion app that a saver session ended.
/// Payload is a JSON string encoded as the notification's `object`.
let kSaverSessionEndedNotification = "haoyu.LunchTalkSaver.sessionEnded"

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
        broadcastSessionSummary()
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

    /// Encode the current session summary as JSON and broadcast via
    /// DistributedNotificationCenter so the companion app can pick it up
    /// and show the summary popup — even though they run in separate processes.
    private func broadcastSessionSummary() {
        let s = store.summary
        let payload: [String: Any] = [
            "title":        s.title,
            "overview":     s.overview,
            "bullets":      s.bullets,
            "inspirations": s.inspirations,
            "highlights":   s.highlights
        ]
        guard
            let data = try? JSONSerialization.data(withJSONObject: payload),
            let jsonString = String(data: data, encoding: .utf8)
        else { return }

        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name(kSaverSessionEndedNotification),
            object: jsonString,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}
