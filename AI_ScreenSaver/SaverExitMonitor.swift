import AppKit
import SwiftUI
import Combine

@MainActor
final class SaverExitMonitor: ObservableObject {
    var onExit: (() -> Void)?

    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var mouseMonitor: Any?
    private var accumulatedMove: CGFloat = 0
    private let moveExitThreshold: CGFloat = 200

    func start() {
        stop()

        // 立即退出事件：按键、点击、滚轮
        let immediateEvents: NSEvent.EventTypeMask = [.keyDown, .leftMouseDown, .rightMouseDown, .scrollWheel]
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: immediateEvents) { [weak self] event in
            self?.triggerExit()
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: immediateEvents) { [weak self] _ in
            self?.triggerExit()
        }

        // 鼠标移动事件：累计移动距离
        mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event: event)
            return event
        }
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
            self.mouseMonitor = nil
        }
        accumulatedMove = 0
    }

    private func handleMouseMoved(event: NSEvent) {
        let dx = event.deltaX
        let dy = event.deltaY
        let distance = sqrt(dx * dx + dy * dy)
        accumulatedMove += distance

        if accumulatedMove >= moveExitThreshold {
            accumulatedMove = 0
            triggerExit()
        }
    }

    private func triggerExit() {
        onExit?()
    }
}

struct SaverExitMonitorView: View {
    let onExit: () -> Void

    @StateObject private var monitor = SaverExitMonitor()

    var body: some View {
        Color.clear
            .onAppear {
                monitor.onExit = onExit
                monitor.start()
            }
            .onDisappear {
                monitor.stop()
            }
    }
}
