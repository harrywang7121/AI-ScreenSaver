import SwiftUI
import AppKit

enum ContentMode {
    case main
    case saver
}

struct ContentView: View {
    @EnvironmentObject private var store: SessionStore
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

// Background is defined in SharedComponents.swift

// MARK: - Header

private struct HeaderView: View {
    @EnvironmentObject private var store: SessionStore
    @Binding var showSettings: Bool
    let openHistory: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // Logo + title
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.5), lineWidth: 1))
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.4), radius: 10)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("LunchTalk Saver")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(store.sessionTitle)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Spacer()

            HStack(spacing: 10) {
                // Message count
                if store.messages.count > 0 {
                    Label("\(store.messages.count)", systemImage: "message.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.08))
                        .clipShape(Capsule())
                }

                // Running status
                RunningBadge(isRunning: store.isRunning)

                // History button
                Button(action: openHistory) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle())

                // Settings button
                Button(action: { showSettings = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(red: 0.29, green: 0.48, blue: 0.96))
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
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.5), lineWidth: 1))
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.4), radius: 10)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("LunchTalk Saver")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(store.sessionTitle)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
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
        HStack(spacing: 7) {
            ZStack {
                if isRunning {
                    Circle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .scaleEffect(pulse ? 1.5 : 1.0)
                        .opacity(pulse ? 0 : 0.6)
                        .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse)
                }
                Circle()
                    .fill(isRunning ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .shadow(color: isRunning ? .green.opacity(0.8) : .clear, radius: 4)
            }
            Text(isRunning ? "对话中" : "已停止")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
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
                LazyVStack(spacing: 16) {
                    ForEach(store.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
            .onChange(of: store.messages.count) { _, _ in
                guard let lastId = store.messages.last?.id else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
        .background {
            if #available(macOS 26, *) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Chat Bubble

private struct ChatBubbleView: View {
    @EnvironmentObject private var store: SessionStore
    let message: Message
    @State private var appeared = false

    private var isExplorer: Bool { message.role == .explorer }
    private var accentColor: Color { isExplorer ? Color(red: 0.29, green: 0.48, blue: 0.96) : Color(red: 0.00, green: 0.79, blue: 0.63) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
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
        .offset(y: appeared ? 0 : 16)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private var avatarView: some View {
        let name = isExplorer ? store.roleAName : store.roleBName
        let initial = String(name.prefix(1)).uppercased()
        return ZStack {
            Circle()
                .fill(accentColor.opacity(0.2))
                .frame(width: 38, height: 38)
                .overlay(
                    Circle()
                        .stroke(accentColor.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: accentColor.opacity(0.5), radius: 8)
            Text(initial)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var bubbleCard: some View {
        VStack(alignment: isExplorer ? .leading : .trailing, spacing: 8) {
            // Role & badge
            HStack(spacing: 6) {
                Text(isExplorer ? store.roleAName : store.roleBName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
                Text(message.role.badgeText)
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundStyle(accentColor)
            }

            // Message content
            messageContentView

            // Time
            Text(timeText)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background {
            if #available(macOS 26, *) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .shadow(color: accentColor.opacity(0.2), radius: 12, x: 0, y: 4)
        .frame(maxWidth: 440, alignment: isExplorer ? .leading : .trailing)
    }

    @ViewBuilder
    private var messageContentView: some View {
        if message.text == "思考中…" {
            ThinkingDotsView(color: accentColor)
        } else {
            Text(message.text)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundStyle(.white.opacity(0.92))
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
        VStack(alignment: .leading, spacing: 14) {
            // Title
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.yellow.opacity(0.9))
                Text("实时摘要")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            if !summary.overview.isEmpty {
                Text(summary.overview)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineSpacing(3)
            }

            FutureSummarySection(title: "要点", items: summary.bullets, accentColor: Color(red: 0.29, green: 0.48, blue: 0.96), icon: "doc.text")
            FutureSummarySection(title: "灵感点", items: summary.inspirations, accentColor: Color(red: 1.0, green: 0.65, blue: 0.1), icon: "lightbulb")

            if !summary.highlights.isEmpty {
                FutureSummarySection(title: "高亮金句", items: summary.highlights, accentColor: Color(red: 0.72, green: 0.35, blue: 0.95), icon: "quote.bubble")
            }

            Spacer()
        }
        .padding(18)
        .background {
            if #available(macOS 26, *) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - Footer

private struct FooterView: View {
    @EnvironmentObject private var store: SessionStore
    let endAction: () -> Void
    let restartAction: () -> Void

    var body: some View {
        HStack {
            // Duration
            VStack(alignment: .leading, spacing: 2) {
                Label("Session 时长", systemImage: "timer")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(store.sessionDurationText)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button(action: restartAction) {
                    Label("重新开始", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(GlassButtonStyle())

                Button(action: endAction) {
                    Label("结束", systemImage: "stop.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.85, green: 0.25, blue: 0.30))
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 0.85, green: 0.25, blue: 0.30).opacity(0.5), radius: 8)
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
            Color(red: 0.024, green: 0.031, blue: 0.063).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Label("设置", systemImage: "slider.horizontal.3")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.bottom, 4)

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
                .frame(minWidth: 480, minHeight: 460)
                .onChange(of: store.historyRetentionDays) { _, _ in
                    store.applyHistoryPolicy()
                }
                .onChange(of: store.maxHistoryCount) { _, _ in
                    store.applyHistoryPolicy()
                }

                HStack {
                    Spacer()
                    Button("完成") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
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
            // Background
            Color(red: 0.024, green: 0.031, blue: 0.063).ignoresSafeArea()

            // Aurora
            Ellipse()
                .fill(Color(red: 0.18, green: 0.22, blue: 0.85).opacity(0.3))
                .frame(width: 400, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -100)

            VStack(alignment: .leading, spacing: 0) {
                // Title area
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(Circle().stroke(Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.4), lineWidth: 1))
                            .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.5), radius: 10)
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Session 摘要")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(store.summary.title)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                .padding(.bottom, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if !store.summary.overview.isEmpty {
                            Text(store.summary.overview)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.75))
                                .padding(12)
                                .background(.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        FutureSummarySection(title: "摘要", items: store.summary.bullets,
                            accentColor: Color(red: 0.29, green: 0.48, blue: 0.96), icon: "doc.text")
                        FutureSummarySection(title: "灵感点", items: store.summary.inspirations,
                            accentColor: Color(red: 1.0, green: 0.65, blue: 0.1), icon: "lightbulb.fill")
                        if !store.summary.highlights.isEmpty {
                            FutureSummarySection(title: "高亮金句", items: store.summary.highlights,
                                accentColor: Color(red: 0.72, green: 0.35, blue: 0.95), icon: "quote.bubble.fill")
                        }
                    }
                }

                // Bottom buttons
                HStack(spacing: 10) {
                    Button(action: copySummary) {
                        Label("复制摘要", systemImage: "doc.on.clipboard")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    Button(action: { openWindow(id: "main") }) {
                        Label("查看对话", systemImage: "bubble.left.and.bubble.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.29, green: 0.48, blue: 0.96))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.4), radius: 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 16)
            }
            .padding(24)
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
        .frame(width: 1280, height: 720)
}
