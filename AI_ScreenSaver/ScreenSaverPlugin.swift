import AppKit
import ScreenSaver
import SwiftUI

@objc(LunchTalkScreenSaverView)
final class LunchTalkScreenSaverView: ScreenSaverView {
    private var hostingView: NSHostingView<AnyView>?
    private var store = SessionStore()

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
        setupHostingView(frame: bounds)
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

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        hostingView?.frame = bounds
    }

    override func layout() {
        super.layout()
        hostingView?.frame = bounds
    }

    private func setupHostingView(frame: NSRect) {
        let rootView = SaverContentView(store: store)
        let hostingView = NSHostingView(rootView: AnyView(rootView))
        hostingView.frame = bounds
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)
        self.hostingView = hostingView
    }
}
