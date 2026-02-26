import AppKit
import ScreenSaver
import SwiftUI

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
}
