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
    @State private var backdropBreathing = false
    let mode: ContentMode

    private var isSaverMode: Bool {
        mode == .saver
    }

    var body: some View {
        ZStack {
            AppleBackdropView()

            VStack(spacing: 18) {
                if !isSaverMode {
                    HeaderView(showSettings: $showSettings) {
                        openWindow(id: "history")
                    }
                } else {
                    SaverHeaderView()
                }

                HStack(alignment: .top, spacing: 16) {
                    ChatListView()

                    if store.showSummaryInSaver {
                        SummarySidePanel(summary: store.summary)
                            .frame(maxWidth: 340)
                    }
                }

                if !isSaverMode {
                    FooterView(
                        endAction: endSession,
                        restartAction: store.restartSession
                    )
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
        .onAppear {
            if !isSaverMode && !store.isRunning {
                store.startSession()
            }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                backdropBreathing = true
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

private struct HeaderView: View {
    @EnvironmentObject private var store: SessionStore

    @Binding var showSettings: Bool
    let openHistory: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LunchTalk Saver")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(store.sessionTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            HStack(spacing: 10) {
                RunningBadge(isRunning: store.isRunning)

                Button("历史") {
                    openHistory()
                }
                .buttonStyle(GlassButtonStyle())

                Button("设置") {
                    showSettings = true
                }
                .buttonStyle(GlassProminentButtonStyle())
            }
        }
        .padding(.horizontal, 2)
    }
}

private struct SaverHeaderView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LunchTalk Saver")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(store.sessionTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            RunningBadge(isRunning: store.isRunning)
        }
        .padding(.horizontal, 2)
    }
}

private struct RunningBadge: View {
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRunning ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(isRunning ? "对话中" : "已停止")
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .foregroundStyle(.white.opacity(0.95))
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct ChatListView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(store.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
            .onChange(of: store.messages.count) { _, _ in
                guard let lastId = store.messages.last?.id else { return }
                withAnimation(.easeOut(duration: 0.35)) {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct ChatBubbleView: View {
    @EnvironmentObject private var store: SessionStore

    let message: Message

    var body: some View {
        HStack {
            if message.role == .explorer {
                bubble
                Spacer(minLength: 46)
            } else {
                Spacer(minLength: 46)
                bubble
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: message.role == .explorer ? .leading : .trailing, spacing: 7) {
            HStack(spacing: 8) {
                Text(nameForRole)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))

                Text(message.role.badgeText)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(message.role.backgroundTint.opacity(0.55))
                    .clipShape(Capsule())
            }

            Text(message.text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(Self.timeFormatter.string(from: message.time))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.56))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(message.role == .explorer ? Color.white.opacity(0.10) : Color.accentColor.opacity(0.30))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: 460, alignment: message.role == .explorer ? .leading : .trailing)
        .transition(.asymmetric(insertion: .move(edge: message.role == .explorer ? .leading : .trailing).combined(with: .opacity), removal: .opacity))
    }

    private var nameForRole: String {
        switch message.role {
        case .explorer: return store.roleAName
        case .builder: return store.roleBName
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private struct SummarySidePanel: View {
    let summary: SessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("实时摘要")
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            if !summary.overview.isEmpty {
                Text(summary.overview)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.82))
            }

            SummarySection(title: "要点", items: summary.bullets)
            SummarySection(title: "灵感点", items: summary.inspirations)

            if !summary.highlights.isEmpty {
                SummarySection(title: "高亮金句", items: summary.highlights)
            }

            Spacer()
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct SummarySection: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.72))

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 7) {
                    Circle()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 4, height: 4)
                        .padding(.top, 6)
                    Text(item)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct FooterView: View {
    @EnvironmentObject private var store: SessionStore

    let endAction: () -> Void
    let restartAction: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Session 时长")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.66))
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(store.sessionDurationText)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Button("重新开始") {
                    restartAction()
                }
                .buttonStyle(GlassButtonStyle())

                Button("结束并弹窗") {
                    endAction()
                }
                .buttonStyle(GlassProminentButtonStyle())
            }
        }
        .padding(.horizontal, 2)
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .padding(.bottom, 2)

            Form {
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
                Button("完成") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(22)
    }
}

struct SummaryWindowView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            AppleBackdropView()

            VStack(alignment: .leading, spacing: 16) {
                Text(store.summary.title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                if !store.summary.overview.isEmpty {
                    Text(store.summary.overview)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.82))
                }

                SummarySection(title: "摘要", items: store.summary.bullets)
                SummarySection(title: "灵感点", items: store.summary.inspirations)

                if !store.summary.highlights.isEmpty {
                    SummarySection(title: "高亮金句", items: store.summary.highlights)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button("复制摘要") { copySummary() }
                        .buttonStyle(GlassButtonStyle())

                    Button("打开完整对话") { openWindow(id: "main") }
                        .buttonStyle(GlassButtonStyle())

                    Button("历史记录") { openWindow(id: "history") }
                        .buttonStyle(GlassButtonStyle())

                    Button("关闭") { dismiss() }
                        .buttonStyle(GlassProminentButtonStyle())
                }
            }
            .padding(24)
        }
        .onAppear { scheduleAutoDismissIfNeeded() }
        .onChange(of: store.autoDismissSeconds) { _, _ in
            scheduleAutoDismissIfNeeded()
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
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
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(store.summaryText, forType: .string)
        #endif
    }
}

private struct AppleBackdropView: View {
    var isBreathing: Bool = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.07, blue: 0.15),
                Color(red: 0.09, green: 0.11, blue: 0.20),
                Color(red: 0.16, green: 0.11, blue: 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 420, height: 420)
                .blur(radius: 50)
                .offset(x: -120, y: -160)
                .scaleEffect(isBreathing ? 1.08 : 0.94)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.blue.opacity(0.16))
                .frame(width: 520, height: 520)
                .blur(radius: 80)
                .offset(x: 140, y: 180)
                .scaleEffect(isBreathing ? 0.95 : 1.08)
        }
    }
}

private struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.30 : 0.18), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct GlassProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.22, green: 0.50, blue: 0.98), Color(red: 0.34, green: 0.65, blue: 1.0)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.28 : 0.16), lineWidth: 1)
            }
            .shadow(color: Color.blue.opacity(0.30), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ContentView(mode: .main)
        .environmentObject(SessionStore())
        .frame(width: 1280, height: 720)
}
