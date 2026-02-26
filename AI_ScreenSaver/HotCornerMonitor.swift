import AppKit
import SwiftUI
import Combine

@MainActor
final class HotCornerMonitor: ObservableObject {
    var onTrigger: (() -> Void)?

    var threshold: CGFloat = 6
    var cooldownSeconds: Double = 1.5

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var lastTrigger: Date?

    func start() {
        stop()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.handlePotentialTrigger()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handlePotentialTrigger()
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func handlePotentialTrigger() {
        let location = NSEvent.mouseLocation
        guard isInHotCorner(location: location) else { return }
        if let lastTrigger, Date().timeIntervalSince(lastTrigger) < cooldownSeconds {
            return
        }
        lastTrigger = Date()
        onTrigger?()
    }

    private func isInHotCorner(location: CGPoint) -> Bool {
        for screen in NSScreen.screens {
            let frame = screen.frame
            let withinX = location.x <= frame.minX + threshold
            let withinY = location.y >= frame.maxY - threshold
            if withinX && withinY && frame.contains(location) {
                return true
            }
        }
        return false
    }
}

struct HotCornerMonitorView: View {
    @Binding var isEnabled: Bool
    @Binding var threshold: Double
    let onTrigger: () -> Void

    @StateObject private var monitor = HotCornerMonitor()

    var body: some View {
        Color.clear
            .onAppear {
                monitor.onTrigger = onTrigger
                monitor.threshold = CGFloat(threshold)
                if isEnabled {
                    monitor.start()
                }
            }
            .onChange(of: isEnabled) { _, newValue in
                if newValue {
                    monitor.start()
                } else {
                    monitor.stop()
                }
            }
            .onChange(of: threshold) { _, newValue in
                monitor.threshold = CGFloat(newValue)
            }
            .onDisappear {
                monitor.stop()
            }
    }
}
