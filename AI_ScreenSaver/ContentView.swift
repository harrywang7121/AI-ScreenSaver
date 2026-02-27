import SwiftUI
import AppKit

enum ContentMode {
    case main
    case saver
}

struct ContentView: View {
    @EnvironmentObject private var store: SessionStore
    @EnvironmentObject private var bridge: SaverNotificationBridge
    @Environment(\.openWindow) private var openWindow

    @State private var showSettings = false
    let mode: ContentMode

    private var isSaverMode: Bool {
        mode == .saver
    }

    var body: some View {
        ZStack {
            BackgroundView()

            VStack(spacing: 20) {
                if !isSaverMode {
                    HeaderView(showSettings: $showSettings) {
                        openWindow(id: "history")
                    }
                } else {
                    SaverHeaderView()
                }

                HStack(alignment: .top, spacing: 18) {
                    ChatListView()

                    if store.showSummaryInSaver {
                        SummarySidePanel(summary: store.summary)
                            .frame(maxWidth: 320)
                    }
                }

                if !isSaverMode {
                    FooterView(
                        endAction: endSession,
                        restartAction: store.restartSession
                    )
                }
            }
            .padding(28)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
        .onAppear {
            if !isSaverMode && !store.isRunning {
                store.startSession()
            }
        }
        // React to .saver bundle finishing: update summary and open popup.
        // Use eventCount (Int, Equatable) as trigger; read actual payload from bridge.
        .onChange(of: bridge.eventCount) { _, _ in
            guard !isSaverMode, let payload = bridge.latestPayload else { return }
            store.summary = SessionSummary(
                title:        payload["title"]        as? String   ?? store.sessionTitle,
                overview:     payload["overview"]     as? String   ?? "",
                bullets:      payload["bullets"]      as? [String] ?? [],
                inspirations: payload["inspirations"] as? [String] ?? [],
                highlights:   payload["highlights"]   as? [String] ?? []
            )
            if store.showPopupOnExit {
                openWindow(id: "summary")
            }
        }
        .overlay {
            if !isSaverMode {
                HotCornerMonitorView(
                    isEnabled: $store.hotCornerEnabled,
                    threshold: $store.hotCornerThreshold
                ) {
                    openWindow(id: "saver")
                }
            }
        }
    }

    private func endSession() {
        store.endSession()
        if store.showPopupOnExit {
            openWindow(id: "summary")
        }
    }
}

// MARK: - Header

private struct HeaderView: View {
    @EnvironmentObject private var store: SessionStore
    @Binding var showSettings: Bool
    let openHistory: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // Logo + title with futuristic glow
            HStack(spacing: 12) {
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.35), .clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 28
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.7), radius: 14)

                    // Neon ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.29, green: 0.48, blue: 0.96),
                                    Color(red: 0.55, green: 0.20, blue: 0.80),
                                    Color(red: 0.29, green: 0.48, blue: 0.96)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 46, height: 46)
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.8), radius: 6)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.9), radius: 5)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("LunchTalk Saver")
                        .font(.system(size: 23, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.7, green: 0.85, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .white.opacity(0.3), radius: 2)

                    Text(store.sessionTitle)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            HStack(spacing: 14) {
                // Message count badge with neon effect
                if store.messages.count > 0 {
                    HStack(spacing: 7) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(store.messages.count)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        if #available(macOS 26.0, *) {
                            Capsule()
                                .fill(.clear)
                                .glassEffect(.regular, in: Capsule())
                        } else {
                            Capsule()
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .neonBorder(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.6), cornerRadius: 22)
                    .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.4), radius: 8)
                }

                // Running status
                RunningBadge(isRunning: store.isRunning)

                // History button
                Button(action: openHistory) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(GlassButtonStyle())

                // Settings button
                Button(action: { showSettings = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(GlassButtonStyle())
            }
        }
    }
}

private struct SaverHeaderView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        HStack(alignment: .top) {
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.3), .clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 24
                            )
                        )
                        .frame(width: 42, height: 42)
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.6), radius: 12)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(red: 0.29, green: 0.48, blue: 0.96), Color(red: 0.55, green: 0.20, blue: 0.80)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 42, height: 42)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.8), radius: 4)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("LunchTalk Saver")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(store.sessionTitle)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Spacer()

            RunningBadge(isRunning: store.isRunning)
        }
    }
}

private struct RunningBadge: View {
    let isRunning: Bool
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                if isRunning {
                    // Pulsing outer ring
                    Circle()
                        .fill(Color.green.opacity(0.45))
                        .frame(width: 20, height: 20)
                        .scaleEffect(pulse ? 1.7 : 1.0)
                        .opacity(pulse ? 0 : 0.9)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
                }
                // Core indicator
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isRunning ?
                                [Color.green.opacity(0.9), Color.green.opacity(0.6)] :
                                [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 6
                        )
                    )
                    .frame(width: 10, height: 10)
                    .shadow(color: isRunning ? .green.opacity(0.95) : .clear, radius: 7)
            }

            Text(isRunning ? "对话中" : "已停止")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            if #available(macOS 26.0, *) {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular, in: Capsule())
            } else {
                Capsule()
                    .fill(.ultraThinMaterial)
            }
        }
        .neonBorder(
            color: isRunning ? Color.green.opacity(0.7) : Color.white.opacity(0.25),
            cornerRadius: 22
        )
        .shadow(
            color: isRunning ? Color.green.opacity(0.5) : .clear,
            radius: 10
        )
        .onAppear { pulse = isRunning }
        .onChange(of: isRunning) { _, v in pulse = v }
    }
}

// MARK: - Chat List

private struct ChatListView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(store.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 18)
            }
            .onChange(of: store.messages.count) { _, _ in
                guard let lastId = store.messages.last?.id else { return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
        .background {
            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .neonBorder(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.45), cornerRadius: 34)
        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.25), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Chat Bubble

private struct ChatBubbleView: View {
    @EnvironmentObject private var store: SessionStore
    let message: Message
    @State private var appeared = false

    private var isExplorer: Bool { message.role == .explorer }
    private var accentColor: Color {
        isExplorer ? Color(red: 0.29, green: 0.48, blue: 0.96) : Color(red: 0.00, green: 0.79, blue: 0.63)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            if isExplorer {
                avatarView
                bubbleCard
                Spacer(minLength: 60)
            } else {
                Spacer(minLength: 60)
                bubbleCard
                avatarView
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }

    private var avatarView: some View {
        let name = isExplorer ? store.roleAName : store.roleBName
        let initial = String(name.prefix(1)).uppercased()
        return ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentColor.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 28
                    )
                )
                .frame(width: 50, height: 50)
                .shadow(color: accentColor.opacity(0.75), radius: 14)

            // Inner filled circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accentColor.opacity(0.35), accentColor.opacity(0.18)],
                        center: .center,
                        startRadius: 5,
                        endRadius: 22
                    )
                )
                .frame(width: 44, height: 44)

            // Neon border
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.6), accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: 44, height: 44)
                .shadow(color: accentColor.opacity(0.8), radius: 6)

            Text(initial)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: accentColor.opacity(0.7), radius: 5)
        }
    }

    private var bubbleCard: some View {
        VStack(alignment: isExplorer ? .leading : .trailing, spacing: 11) {
            // Role & badge
            HStack(spacing: 8) {
                Text(isExplorer ? store.roleAName : store.roleBName)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .shadow(color: accentColor.opacity(0.6), radius: 3)

                Text(message.role.badgeText)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.28))
                            .overlay(
                                Capsule()
                                    .stroke(accentColor.opacity(0.6), lineWidth: 1.5)
                                    .shadow(color: accentColor.opacity(0.5), radius: 3)
                            )
                    )
                    .foregroundStyle(accentColor)
            }

            // Message content
            messageContentView

            // Time
            Text(timeText)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background {
            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .neonBorder(color: accentColor.opacity(0.5), cornerRadius: 24)
        .shadow(color: accentColor.opacity(0.3), radius: 18, x: 0, y: 7)
        .frame(maxWidth: 480, alignment: isExplorer ? .leading : .trailing)
    }

    @ViewBuilder
    private var messageContentView: some View {
        if message.text == "思考中…" {
            ThinkingDotsView(color: accentColor)
        } else {
            Text(message.text)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundStyle(.white.opacity(0.93))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.time)
    }
}

// MARK: - Summary Side Panel

private struct SummarySidePanel: View {
    let summary: SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Title with sparkle glow
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 3,
                                endRadius: 18
                            )
                        )
                        .frame(width: 32, height: 32)
                        .shadow(color: .yellow.opacity(0.7), radius: 10)

                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.yellow)
                        .shadow(color: .yellow.opacity(0.9), radius: 8)
                }

                Text("实时摘要")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            if !summary.overview.isEmpty {
                Text(summary.overview)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineSpacing(5)
                    .padding(14)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.white.opacity(0.15), lineWidth: 1.5)
                            )
                    }
            }

            FutureSummarySection(
                title: "要点",
                items: summary.bullets,
                accentColor: Color(red: 0.29, green: 0.48, blue: 0.96),
                icon: "doc.text"
            )

            FutureSummarySection(
                title: "灵感点",
                items: summary.inspirations,
                accentColor: Color(red: 1.0, green: 0.65, blue: 0.1),
                icon: "lightbulb"
            )

            if !summary.highlights.isEmpty {
                FutureSummarySection(
                    title: "高亮金句",
                    items: summary.highlights,
                    accentColor: Color(red: 0.72, green: 0.35, blue: 0.95),
                    icon: "quote.bubble"
                )
            }

            Spacer()
        }
        .padding(22)
        .background {
            if #available(macOS 26.0, *) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .neonBorder(color: Color.yellow.opacity(0.5), cornerRadius: 34)
        .shadow(color: Color.yellow.opacity(0.25), radius: 16)
    }
}

// MARK: - Footer

private struct FooterView: View {
    @EnvironmentObject private var store: SessionStore
    let endAction: () -> Void
    let restartAction: () -> Void

    var body: some View {
        HStack {
            // Duration with neon accent
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.8))
                    Text("Session 时长")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }

                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(store.sessionDurationText)
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.65, green: 0.82, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.4), radius: 6)
                }
            }

            Spacer()

            HStack(spacing: 14) {
                Button(action: restartAction) {
                    HStack(spacing: 9) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .bold))
                        Text("重新开始")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background {
                        if #available(macOS 26.0, *) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.clear)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .neonBorder(color: .white.opacity(0.35), cornerRadius: 16)
                }
                .buttonStyle(.plain)

                Button(action: endAction) {
                    HStack(spacing: 9) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 15, weight: .black))
                        Text("结束")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 11)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.25, blue: 0.30),
                                Color(red: 0.65, green: 0.15, blue: 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .neonBorder(color: Color(red: 0.85, green: 0.25, blue: 0.30).opacity(0.9), cornerRadius: 16)
                    .shadow(color: Color(red: 0.85, green: 0.25, blue: 0.30).opacity(0.65), radius: 14, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Settings

private struct SettingsView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Dark background with subtle aurora
            Color.black.ignoresSafeArea()

            Ellipse()
                .fill(Color(red: 0.18, green: 0.22, blue: 0.85).opacity(0.18))
                .frame(width: 550, height: 450)
                .blur(radius: 110)
                .offset(x: -110, y: -160)

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color(red: 0.29, green: 0.48, blue: 0.96))
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.7), radius: 8)

                    Text("设置")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 10)

                Form {
                    Section("兴趣标签") {
                        let allTags = ["AI 与产品", "硬件 & 前沿", "投资 & 商业", "效率 & 工作流", "创意 & 设计", "随便聊"]
                        ForEach(allTags, id: \.self) { tag in
                            Toggle(tag, isOn: Binding(
                                get: { store.interestTags.contains(tag) },
                                set: { isOn in
                                    if isOn {
                                        store.interestTags.insert(tag)
                                    } else {
                                        store.interestTags.remove(tag)
                                    }
                                }
                            ))
                        }
                    }

                    Section("对话节奏") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("对话频率：\(Int(store.messageInterval)) 秒/句")
                            Slider(value: $store.messageInterval, in: 6...20, step: 1)
                        }
                        Toggle("在屏保内显示实时摘要", isOn: $store.showSummaryInSaver)
                        Toggle("退出后弹出摘要窗口", isOn: $store.showPopupOnExit)
                    }

                    Section("AI 模型与接口") {
                        TextField("API Endpoint", text: $store.apiEndpoint)
                        TextField("Model 名称", text: $store.apiModel)
                        SecureField("API Key", text: $store.apiKey)
                        Stepper(value: $store.maxOutputTokens, in: 50...500, step: 50) {
                            Text("单次最大输出：\(store.maxOutputTokens) tokens")
                        }
                        Toggle("显示费用估算", isOn: $store.showCostEstimate)
                    }

                    Section("对话风格") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("思维风格：\(store.divergenceLevel < 0.4 ? "偏落地" : store.divergenceLevel > 0.6 ? "偏发散" : "均衡")")
                            Slider(value: $store.divergenceLevel, in: 0...1)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("回复长度：\(store.messageLengthLevel < 0.4 ? "简短" : store.messageLengthLevel > 0.6 ? "详细" : "适中")")
                            Slider(value: $store.messageLengthLevel, in: 0...1)
                        }
                    }

                    Section("弹窗") {
                        Picker("自动消失", selection: $store.autoDismissSeconds) {
                            Text("不自动").tag(0.0)
                            Text("10 秒").tag(10.0)
                            Text("30 秒").tag(30.0)
                        }
                    }

                    Section("触发角") {
                        Toggle("启用左上角触发", isOn: $store.hotCornerEnabled)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("触发灵敏度：\(Int(store.hotCornerThreshold)) px")
                            Slider(value: $store.hotCornerThreshold, in: 2...16, step: 1)
                        }
                    }

                    Section("话题与角色") {
                        TextField("角色 A 名称", text: $store.roleAName)
                        TextField("角色 B 名称", text: $store.roleBName)

                        let personalities = ["默认", "批判型", "教练型", "研究型", "乐观型", "务实型"]
                        Picker("角色 A 性格", selection: $store.roleAPersonality) {
                            ForEach(personalities, id: \.self) { personality in
                                Text(personality).tag(personality)
                            }
                        }
                        Picker("角色 B 性格", selection: $store.roleBPersonality) {
                            ForEach(personalities, id: \.self) { personality in
                                Text(personality).tag(personality)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("话题种子（每行一个）")
                            TextEditor(text: $store.topicSeedText)
                                .frame(height: 110)
                        }
                    }

                    Section("历史与隐私") {
                        Toggle("保存完整对话", isOn: $store.saveFullTranscript)
                        Stepper(value: $store.historyRetentionDays, in: 7...90, step: 1) {
                            Text("保留 \(store.historyRetentionDays) 天")
                        }
                        Stepper(value: $store.maxHistoryCount, in: 10...200, step: 10) {
                            Text("最多保留 \(store.maxHistoryCount) 条")
                        }
                        Button("清空历史") {
                            store.clearHistory()
                        }
                        .buttonStyle(.bordered)
                        .tint(Color(red: 0.78, green: 0.28, blue: 0.30))
                    }
                }
                .frame(minWidth: 520, minHeight: 500)
                .onChange(of: store.historyRetentionDays) { _, _ in
                    store.applyHistoryPolicy()
                }
                .onChange(of: store.maxHistoryCount) { _, _ in
                    store.applyHistoryPolicy()
                }

                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("完成")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 11)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.29, green: 0.48, blue: 0.96),
                                        Color(red: 0.20, green: 0.35, blue: 0.75)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.6), radius: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(26)
        }
    }
}

// MARK: - Summary Window

struct SummaryWindowView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Dark background with aurora
            Color.black.ignoresSafeArea()

            Ellipse()
                .fill(Color(red: 0.18, green: 0.22, blue: 0.85).opacity(0.22))
                .frame(width: 520, height: 370)
                .blur(radius: 105)
                .offset(x: -130, y: -110)

            Ellipse()
                .fill(Color(red: 0.55, green: 0.20, blue: 0.80).opacity(0.17))
                .frame(width: 420, height: 320)
                .blur(radius: 95)
                .offset(x: 110, y: 90)

            VStack(alignment: .leading, spacing: 0) {
                // Title area with glow
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.45), .clear],
                                    center: .center,
                                    startRadius: 6,
                                    endRadius: 32
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.7), radius: 14)

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.29, green: 0.48, blue: 0.96),
                                        Color.yellow,
                                        Color(red: 0.29, green: 0.48, blue: 0.96)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                            .frame(width: 54, height: 54)
                            .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.8), radius: 8)

                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(.white)
                            .shadow(color: .yellow.opacity(0.9), radius: 8)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Session 摘要")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(store.summary.title)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .black))
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                .padding(.bottom, 26)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if !store.summary.overview.isEmpty {
                            Text(store.summary.overview)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(.white.opacity(0.82))
                                .lineSpacing(5)
                                .padding(16)
                                .background {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(.white.opacity(0.15), lineWidth: 1.5)
                                        )
                                }
                        }

                        FutureSummarySection(
                            title: "摘要",
                            items: store.summary.bullets,
                            accentColor: Color(red: 0.29, green: 0.48, blue: 0.96),
                            icon: "doc.text"
                        )

                        FutureSummarySection(
                            title: "灵感点",
                            items: store.summary.inspirations,
                            accentColor: Color(red: 1.0, green: 0.65, blue: 0.1),
                            icon: "lightbulb.fill"
                        )

                        if !store.summary.highlights.isEmpty {
                            FutureSummarySection(
                                title: "高亮金句",
                                items: store.summary.highlights,
                                accentColor: Color(red: 0.72, green: 0.35, blue: 0.95),
                                icon: "quote.bubble.fill"
                            )
                        }
                    }
                }

                // Bottom buttons with futuristic styling
                HStack(spacing: 16) {
                    Button(action: copySummary) {
                        HStack(spacing: 9) {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 14, weight: .bold))
                            Text("复制摘要")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.88))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background {
                            if #available(macOS 26.0, *) {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.clear)
                                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                        .neonBorder(color: .white.opacity(0.35), cornerRadius: 16)
                    }
                    .buttonStyle(.plain)

                    Button(action: { openWindow(id: "main") }) {
                        HStack(spacing: 9) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 15, weight: .black))
                            Text("查看对话")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.29, green: 0.48, blue: 0.96),
                                    Color(red: 0.20, green: 0.35, blue: 0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .neonBorder(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.9), cornerRadius: 16)
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.6), radius: 14, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 22)
            }
            .padding(30)
        }
        .onAppear { scheduleAutoDismissIfNeeded() }
        .onChange(of: store.autoDismissSeconds) { _, _ in scheduleAutoDismissIfNeeded() }
        .onDisappear { autoDismissTask?.cancel() }
    }

    private func scheduleAutoDismissIfNeeded() {
        autoDismissTask?.cancel()
        guard store.autoDismissSeconds > 0 else { return }
        autoDismissTask = Task {
            try? await Task.sleep(for: .seconds(store.autoDismissSeconds))
            if Task.isCancelled { return }
            await MainActor.run { dismiss() }
        }
    }

    private func copySummary() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(store.summaryText, forType: .string)
    }
}

#Preview {
    ContentView(mode: .main)
        .environmentObject(SessionStore())
        .environmentObject(SaverNotificationBridge())
        .frame(width: 1280, height: 720)
}
