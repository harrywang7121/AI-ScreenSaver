import AppKit
import SwiftUI

struct SaverWindowView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ContentView(mode: .saver)
            .background(ScreenSaverWindowConfigurator())
            .overlay(SaverExitMonitorView(onExit: exitSaver))
            .onAppear {
                store.restartSession()
            }
    }

    private func exitSaver() {
        store.endSession()
        dismiss()
        if store.showPopupOnExit {
            openWindow(id: "summary")
        }
    }
}

struct ScreenSaverWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configureWindow(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureWindow(nsView)
        }
    }

    private func configureWindow(_ view: NSView) {
        guard let window = view.window else { return }
        window.level = .screenSaver
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        if let screen = window.screen ?? NSScreen.main {
            window.setFrame(screen.frame, display: true)
        }
        window.makeKeyAndOrderFront(nil)
    }
}
