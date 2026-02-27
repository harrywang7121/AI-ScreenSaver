import SwiftUI
import AppKit

enum ContentMode {
    case main
    case saver
}

// ThinkingDotsView - animated dots for "思考中…"
private struct ThinkingDotsView: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 7, height: 7)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .opacity(animating ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.18),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
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

private struct HeaderView: View {
    @EnvironmentObject private var store: SessionStore

    @Binding var showSettings: Bool
    let openHistory: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LunchTalk Saver")
                    .font(.custom("Avenir Next", size: 28))
                    .foregroundStyle(.white)
                Text(store.sessionTitle)
                    .font(.custom("Avenir Next", size: 16))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            HStack(spacing: 12) {
                if store.messages.count > 0 {
                    Text("💬 \(store.messages.count)")
                        .font(.custom("Avenir Next", size: 13))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .foregroundStyle(.white.opacity(0.85))
                }

                RunningBadge(isRunning: store.isRunning)

                Button("历史") {
                    openHistory()
                }
                .buttonStyle(.bordered)

                Button("设置") {
                    showSettings = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.28, green: 0.44, blue: 0.82))
            }
        }
    }
}

private struct SaverHeaderView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LunchTalk Saver")
                    .font(.custom("Avenir Next", size: 26))
                    .foregroundStyle(.white)
                Text(store.sessionTitle)
                    .font(.custom("Avenir Next", size: 14))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            RunningBadge(isRunning: store.isRunning)
        }
    }
}

private struct RunningBadge: View {
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRunning ? Color.green : Color.gray)
                .frame(width: 10, height: 10)
            Text(isRunning ? "对话中" : "已停止")
                .font(.custom("Avenir Next", size: 14))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.15))
        .clipShape(Capsule())
        .foregroundStyle(.white)
    }
}

private struct ChatListView: View {
    @EnvironmentObject private var store: SessionStore

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 18) {
                    ForEach(store.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
            }
            .onChange(of: store.messages.count) { _, _ in
                guard let lastId = store.messages.last?.id else { return }
                withAnimation(.easeOut(duration: 0.4)) {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct ChatBubbleView: View {
    @EnvironmentObject private var store: SessionStore

    let message: Message
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .explorer {
                avatarView
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
                avatarView
            }
        }
    }

    private var avatarView: some View {
        let initial = (message.role == .explorer ? store.roleAName : store.roleBName).prefix(1).uppercased()
        return ZStack {
            Circle()
                .fill(message.role.bubbleColor)
                .frame(width: 36, height: 36)
            Text(initial)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var messageContent: some View {
        if message.text == "思考中…" {
            ThinkingDotsView()
        } else {
            Text(message.text)
                .font(.custom("Avenir Next", size: 15))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bubble: some View {
        VStack(alignment: message.role == .explorer ? .leading : .trailing, spacing: 6) {
            HStack(spacing: 8) {
                Text(nameForRole)
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundStyle(.white.opacity(0.75))

                Text(message.role.badgeText)
                    .font(.custom("Avenir Next", size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(message.role.backgroundTint.opacity(0.6))
                    .clipShape(Capsule())
            }

            messageContent

            Text(Self.timeFormatter.string(from: message.time))
                .font(.custom("Avenir Next", size: 11))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(message.role.bubbleColor.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: 420, alignment: message.role == .explorer ? .leading : .trailing)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) {
                appeared = true
            }
        }
    }

    private var nameForRole: String {
        switch message.role {
        case .explorer:
            return store.roleAName
        case .builder:
            return store.roleBName
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
        VStack(alignment: .leading, spacing: 16) {
            Text("实时摘要")
                .font(.custom("Avenir Next", size: 18))
                .foregroundStyle(.white)

            if !summary.overview.isEmpty {
                Text(summary.overview)
                    .font(.custom("Avenir Next", size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }

            SummarySection(
                title: "要点",
                items: summary.bullets,
                accentColor: Color(red: 0.24, green: 0.44, blue: 0.92)
            )
            SummarySection(
                title: "灵感点",
                items: summary.inspirations,
                accentColor: Color(red: 0.95, green: 0.60, blue: 0.20)
            )

            if !summary.highlights.isEmpty {
                SummarySection(
                    title: "高亮金句",
                    items: summary.highlights,
                    accentColor: Color(red: 0.72, green: 0.40, blue: 0.85)
                )
            }

            Spacer()
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct SummarySection: View {
    let title: String
    let items: [String]
    let accentColor: Color

    init(title: String, items: [String], accentColor: Color = .white.opacity(0.6)) {
        self.title = title
        self.items = items
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 3, height: 14)
                    .cornerRadius(2)
                Text(title)
                    .font(.custom("Avenir Next", size: 13))
                    .foregroundStyle(.white.opacity(0.75))
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .padding(.top, 6)
                    Text(item)
                        .font(.custom("Avenir Next", size: 13))
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
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundStyle(.white.opacity(0.7))
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(store.sessionDurationText)
                        .font(.custom("Avenir Next", size: 18))
                        .foregroundStyle(.white)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button("重新开始") {
                    restartAction()
                }
                .buttonStyle(.bordered)

                Button("结束并弹窗") {
                    endAction()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.78, green: 0.28, blue: 0.30))
            }
        }
        .padding(.horizontal, 6)
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.custom("Avenir Next", size: 22))
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

struct SummaryWindowView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    @State private var autoDismissTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.09, blue: 0.13)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.white.opacity(0.9))
                    Text(store.summary.title)
                        .font(.custom("Avenir Next", size: 20))
                        .foregroundStyle(.white)
                }

                if !store.summary.overview.isEmpty {
                    Text(store.summary.overview)
                        .font(.custom("Avenir Next", size: 13))
                        .foregroundStyle(.white.opacity(0.8))
                }

                SummarySection(
                    title: "摘要",
                    items: store.summary.bullets,
                    accentColor: Color(red: 0.24, green: 0.44, blue: 0.92)
                )
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                SummarySection(
                    title: "💡 灵感点",
                    items: store.summary.inspirations,
                    accentColor: Color(red: 0.95, green: 0.60, blue: 0.20)
                )
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if !store.summary.highlights.isEmpty {
                    SummarySection(
                        title: "高亮金句",
                        items: store.summary.highlights,
                        accentColor: Color(red: 0.72, green: 0.40, blue: 0.85)
                    )
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer()

                HStack(spacing: 12) {
                    Button("复制摘要") {
                        copySummary()
                    }
                    .buttonStyle(.bordered)

                    Button("打开完整对话") {
                        openWindow(id: "main")
                    }
                    .buttonStyle(.bordered)

                    Button("历史记录") {
                        openWindow(id: "history")
                    }
                    .buttonStyle(.bordered)

                    Button("关闭") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.78, green: 0.28, blue: 0.30))
                }
            }
            .padding(22)
        }
        .onAppear {
            scheduleAutoDismissIfNeeded()
        }
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
            await MainActor.run {
                dismiss()
            }
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

private struct BackgroundView: View {
    @State private var pulse = false

    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.08, blue: 0.15),
                Color(red: 0.10, green: 0.13, blue: 0.22),
                Color(red: 0.15, green: 0.10, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            RoundedRectangle(cornerRadius: 60)
                .fill(Color.white.opacity(0.04))
                .frame(width: 520, height: 520)
                .offset(x: -240, y: -200)
                .scaleEffect(pulse ? 1.05 : 0.95)
                .opacity(pulse ? 0.06 : 0.03)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 80)
                .fill(Color.white.opacity(0.03))
                .frame(width: 680, height: 420)
                .offset(x: 260, y: 240)
                .scaleEffect(pulse ? 0.96 : 1.04)
                .opacity(pulse ? 0.04 : 0.025)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview {
    ContentView(mode: .main)
        .environmentObject(SessionStore())
        .frame(width: 1280, height: 720)
}
