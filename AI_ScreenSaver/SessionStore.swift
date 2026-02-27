import Foundation
import SwiftUI
import Combine

struct Message: Identifiable, Hashable {
    let id = UUID()
    let role: Role
    let text: String
    let time: Date
}

struct MessageRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let role: Role
    let text: String
    let time: Date
}

enum Role: String, CaseIterable, Codable {
    case explorer
    case builder

    var displayName: String {
        switch self {
        case .explorer:
            return "发散者"
        case .builder:
            return "落地者"
        }
    }

    var badgeText: String {
        switch self {
        case .explorer:
            return "发散"
        case .builder:
            return "落地"
        }
    }

    var bubbleColor: Color {
        switch self {
        case .explorer:
            return Color(red: 0.24, green: 0.44, blue: 0.92)
        case .builder:
            return Color(red: 0.14, green: 0.60, blue: 0.45)
        }
    }

    var backgroundTint: Color {
        switch self {
        case .explorer:
            return Color(red: 0.20, green: 0.30, blue: 0.60)
        case .builder:
            return Color(red: 0.10, green: 0.40, blue: 0.30)
        }
    }
}

struct SessionSummary: Hashable {
    var title: String
    var overview: String
    var bullets: [String]
    var inspirations: [String]
    var highlights: [String]

    static let empty = SessionSummary(
        title: "未开始",
        overview: "",
        bullets: [],
        inspirations: [],
        highlights: []
    )
}

struct SessionSummaryRecord: Codable, Hashable {
    var title: String
    var overview: String
    var bullets: [String]
    var inspirations: [String]
    var highlights: [String]
}

struct SessionRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let start: Date
    let end: Date
    let topic: String
    let summary: SessionSummaryRecord
    let messages: [MessageRecord]
}

@MainActor
final class SessionStore: ObservableObject {
    @Published var messages: [Message]
    @Published var summary: SessionSummary
    @Published var isRunning: Bool

    // 基础设置
    @Published var showSummaryInSaver: Bool {
        didSet { UserDefaults.standard.set(showSummaryInSaver, forKey: "showSummaryInSaver") }
    }
    @Published var showPopupOnExit: Bool {
        didSet { UserDefaults.standard.set(showPopupOnExit, forKey: "showPopupOnExit") }
    }
    @Published var messageInterval: Double {
        didSet { UserDefaults.standard.set(messageInterval, forKey: "messageInterval") }
    }
    @Published var autoDismissSeconds: Double {
        didSet { UserDefaults.standard.set(autoDismissSeconds, forKey: "autoDismissSeconds") }
    }

    // 话题与角色
    @Published var topicSeedText: String {
        didSet { UserDefaults.standard.set(topicSeedText, forKey: "topicSeedText") }
    }
    @Published var roleAName: String {
        didSet { UserDefaults.standard.set(roleAName, forKey: "roleAName") }
    }
    @Published var roleBName: String {
        didSet { UserDefaults.standard.set(roleBName, forKey: "roleBName") }
    }

    // 历史记录
    @Published var history: [SessionRecord]
    @Published var saveFullTranscript: Bool {
        didSet { UserDefaults.standard.set(saveFullTranscript, forKey: "saveFullTranscript") }
    }
    @Published var historyRetentionDays: Int {
        didSet { UserDefaults.standard.set(historyRetentionDays, forKey: "historyRetentionDays") }
    }
    @Published var maxHistoryCount: Int {
        didSet { UserDefaults.standard.set(maxHistoryCount, forKey: "maxHistoryCount") }
    }

    // 热角设置
    @Published var hotCornerEnabled: Bool {
        didSet { UserDefaults.standard.set(hotCornerEnabled, forKey: "hotCornerEnabled") }
    }
    @Published var hotCornerThreshold: Double {
        didSet { UserDefaults.standard.set(hotCornerThreshold, forKey: "hotCornerThreshold") }
    }

    // AI 模型与接口
    @Published var apiEndpoint: String {
        didSet { UserDefaults.standard.set(apiEndpoint, forKey: "apiEndpoint") }
    }
    @Published var apiModel: String {
        didSet { UserDefaults.standard.set(apiModel, forKey: "apiModel") }
    }
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "apiKey") }
    }
    @Published var maxOutputTokens: Int {
        didSet { UserDefaults.standard.set(maxOutputTokens, forKey: "maxOutputTokens") }
    }
    @Published var showCostEstimate: Bool {
        didSet { UserDefaults.standard.set(showCostEstimate, forKey: "showCostEstimate") }
    }

    // 对话风格
    @Published var divergenceLevel: Double {
        didSet { UserDefaults.standard.set(divergenceLevel, forKey: "divergenceLevel") }
    }
    @Published var messageLengthLevel: Double {
        didSet { UserDefaults.standard.set(messageLengthLevel, forKey: "messageLengthLevel") }
    }
    @Published var roleAPersonality: String {
        didSet { UserDefaults.standard.set(roleAPersonality, forKey: "roleAPersonality") }
    }
    @Published var roleBPersonality: String {
        didSet { UserDefaults.standard.set(roleBPersonality, forKey: "roleBPersonality") }
    }

    // 兴趣标签
    @Published var interestTags: Set<String> {
        didSet {
            let arr = Array(interestTags)
            UserDefaults.standard.set(arr, forKey: "interestTags")
        }
    }

    var sessionStart: Date?
    var sessionEnd: Date?

    private var messageTask: Task<Void, Never>?
    private var messageIndex: Int
    private var currentTopic: String
    private var hasLoadedHistory: Bool

    init() {
        self.messages = []
        self.summary = .empty
        self.isRunning = false

        // 从 UserDefaults 读取基础设置
        self.showSummaryInSaver = UserDefaults.standard.object(forKey: "showSummaryInSaver") as? Bool ?? true
        self.showPopupOnExit = UserDefaults.standard.object(forKey: "showPopupOnExit") as? Bool ?? true
        self.messageInterval = UserDefaults.standard.object(forKey: "messageInterval") as? Double ?? 8
        self.autoDismissSeconds = UserDefaults.standard.object(forKey: "autoDismissSeconds") as? Double ?? 0

        // 话题与角色
        self.topicSeedText = UserDefaults.standard.string(forKey: "topicSeedText") ?? "AI 助手在工作流中的价值\n更高效的产品评审方式\n如何让团队形成知识复用\n硬件 + AI 的新交互"
        self.roleAName = UserDefaults.standard.string(forKey: "roleAName") ?? "Nova"
        self.roleBName = UserDefaults.standard.string(forKey: "roleBName") ?? "Anchor"

        // 历史记录
        self.history = []
        self.saveFullTranscript = UserDefaults.standard.object(forKey: "saveFullTranscript") as? Bool ?? true
        self.historyRetentionDays = UserDefaults.standard.object(forKey: "historyRetentionDays") as? Int ?? 30
        self.maxHistoryCount = UserDefaults.standard.object(forKey: "maxHistoryCount") as? Int ?? 50

        // 热角设置
        self.hotCornerEnabled = UserDefaults.standard.object(forKey: "hotCornerEnabled") as? Bool ?? true
        self.hotCornerThreshold = UserDefaults.standard.object(forKey: "hotCornerThreshold") as? Double ?? 6

        // AI 模型与接口
        self.apiEndpoint = UserDefaults.standard.string(forKey: "apiEndpoint") ?? "https://api.openai.com/v1"
        self.apiModel = UserDefaults.standard.string(forKey: "apiModel") ?? "gpt-4o-mini"
        self.apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        self.maxOutputTokens = UserDefaults.standard.object(forKey: "maxOutputTokens") as? Int ?? 200
        self.showCostEstimate = UserDefaults.standard.object(forKey: "showCostEstimate") as? Bool ?? false

        // 对话风格
        self.divergenceLevel = UserDefaults.standard.object(forKey: "divergenceLevel") as? Double ?? 0.5
        self.messageLengthLevel = UserDefaults.standard.object(forKey: "messageLengthLevel") as? Double ?? 0.3
        self.roleAPersonality = UserDefaults.standard.string(forKey: "roleAPersonality") ?? "默认"
        self.roleBPersonality = UserDefaults.standard.string(forKey: "roleBPersonality") ?? "务实型"

        // 兴趣标签
        let savedTags = UserDefaults.standard.stringArray(forKey: "interestTags") ?? []
        self.interestTags = Set(savedTags)

        self.messageIndex = 0
        self.currentTopic = "AI 助手在工作流中的价值"
        self.hasLoadedHistory = false
        loadHistoryIfNeeded()
    }

    var sessionTitle: String {
        guard let start = sessionStart else {
            return "午休对话"
        }
        let end = sessionEnd ?? Date()
        let startText = Self.timeFormatter.string(from: start)
        let endText = Self.timeFormatter.string(from: end)
        return "午休对话 · \(startText)–\(endText)"
    }

    var sessionDurationText: String {
        guard let start = sessionStart else {
            return "未开始"
        }
        let end = sessionEnd ?? Date()
        let interval = max(0, end.timeIntervalSince(start))
        let minutes = Int(interval / 60)
        let seconds = Int(interval) % 60
        return String(format: "%02dm %02ds", minutes, seconds)
    }

    var summaryText: String {
        var lines: [String] = []
        lines.append(summary.title)
        if !summary.overview.isEmpty {
            lines.append(summary.overview)
        }
        if !summary.bullets.isEmpty {
            lines.append("\n摘要")
            lines.append(contentsOf: summary.bullets.map { "• \($0)" })
        }
        if !summary.inspirations.isEmpty {
            lines.append("\n灵感点")
            lines.append(contentsOf: summary.inspirations.map { "• \($0)" })
        }
        if !summary.highlights.isEmpty {
            lines.append("\n金句")
            lines.append(contentsOf: summary.highlights.map { "• \($0)" })
        }
        return lines.joined(separator: "\n")
    }

    func startSession() {
        resetSession()
        isRunning = true
        sessionStart = Date()
        currentTopic = pickTopic()
        appendMessage(for: .explorer)
        appendMessage(for: .builder)
        startAutoMessages()
        updateSummary(force: true)
    }

    func endSession() {
        guard isRunning || sessionStart != nil else { return }
        isRunning = false
        sessionEnd = Date()
        messageTask?.cancel()
        updateSummary(force: true)
        saveSessionToHistory()
    }

    func restartSession() {
        endSession()
        startSession()
    }

    func clearHistory() {
        history = []
        persistHistory()
    }

    func applyHistoryPolicy() {
        history = filteredHistory(history)
        persistHistory()
    }

    func appendNextMessage() {
        guard isRunning else { return }
        let nextRole: Role = messages.last?.role == .explorer ? .builder : .explorer
        appendMessage(for: nextRole)
    }

    private func resetSession() {
        messages = []
        summary = .empty
        sessionStart = nil
        sessionEnd = nil
        messageIndex = 0
        messageTask?.cancel()
    }

    private func startAutoMessages() {
        messageTask?.cancel()
        messageTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.messageInterval))
                if Task.isCancelled { break }
                await MainActor.run {
                    self.appendNextMessage()
                }
            }
        }
    }

    private func appendMessage(for role: Role) {
        messageIndex += 1
        if messageIndex % 8 == 0 {
            currentTopic = pickTopic()
        }

        // 先添加占位消息
        let placeholder = Message(role: role, text: "思考中…", time: Date())
        messages.append(placeholder)
        let placeholderIndex = messages.count - 1

        // 在后台异步生成消息
        Task { [weak self] in
            guard let self = self else { return }
            let generatedText = await self.generateMessage(for: role, topic: self.currentTopic)

            await MainActor.run {
                // 用真实内容替换占位消息
                if placeholderIndex < self.messages.count {
                    let updatedMessage = Message(role: role, text: generatedText, time: Date())
                    self.messages[placeholderIndex] = updatedMessage
                }

                // 定期更新摘要
                if self.messageIndex % 4 == 0 {
                    self.updateSummary(force: false)
                }
            }
        }
    }

    private func pickTopic() -> String {
        let seeds = topicSeedText
            .split { $0 == "\n" || $0 == "," }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return seeds.randomElement() ?? "更高效的工作方式"
    }

    private func generateMessage(for role: Role, topic: String) async -> String {
        // 如果 API Key 为空，直接返回模板
        guard !apiKey.isEmpty else {
            return nextMessageText(for: role)
        }

        // 计算目标长度
        let targetLength = Int(40 + messageLengthLevel * 80)

        // 构建系统提示词
        let systemPrompt: String
        switch role {
        case .explorer:
            systemPrompt = "你是一个创意思维者叫 \(roleAName)，性格\(roleAPersonality)，话题：\(topic)。风格：发散、提问。请用简洁中文（\(targetLength)字以内）提出有价值的问题或想法。"
        case .builder:
            systemPrompt = "你是务实执行者叫 \(roleBName)，性格\(roleBPersonality)，话题：\(topic)。风格：落地、具体可操作。请用简洁中文（\(targetLength)字以内）给出具体建议或下一步行动。"
        }

        // 构建历史上下文（最近6条消息）
        var apiMessages: [[String: String]] = [["role": "system", "content": systemPrompt]]
        let recentMessages = messages.suffix(6)
        for msg in recentMessages {
            let apiRole = msg.role == .explorer ? "user" : "assistant"
            apiMessages.append(["role": apiRole, "content": msg.text])
        }

        // 构建请求体
        let requestBody: [String: Any] = [
            "model": apiModel,
            "messages": apiMessages,
            "max_tokens": maxOutputTokens,
            "temperature": 0.7
        ]

        // 发送 API 请求
        do {
            guard let url = URL(string: "\(apiEndpoint)/chat/completions") else {
                return nextMessageText(for: role)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("API request failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return nextMessageText(for: role)
            }

            // 解析响应
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return nextMessageText(for: role)
        } catch {
            print("API error: \(error.localizedDescription)")
            return nextMessageText(for: role)
        }
    }

    private func nextMessageText(for role: Role) -> String {
        let topic = currentTopic
        switch role {
        case .explorer:
            let templates = [
                "如果把 \(topic) 当成一个长期资产，我们现在最被低估的环节是什么？",
                "有没有办法用 \(topic) 做一个更轻的切入点，先让团队尝到甜头？",
                "\(topic) 里最值得做成默认流程的动作可能是哪一个？",
                "从用户感知角度，\(topic) 应该先解决哪种「烦躁时刻」？",
                "我们能不能把 \(topic) 拆成三个层级：探索、验证、规模化？",
                "要是把 \(topic) 当成产品卖给自己，你觉得核心卖点是哪一句？"
            ]
            return templates.randomElement() ?? "我们可以先从 \(topic) 的轻量验证入手。"
        case .builder:
            let templates = [
                "可以先选 1 个典型场景，定义输入、输出和成功指标，再迭代。",
                "我建议把 \(topic) 的动作拆成三步：触发、生成、回收。",
                "我们需要一个可观测指标，比如节省的时间或减少的沟通轮次。",
                "落地上先做最小闭环：收集需求、生成建议、导出可执行清单。",
                "建议设一个 2 周的小实验，验证是否提升决策速度。",
                "关键是节奏，先把对话频率和摘要质量稳定下来。"
            ]
            return templates.randomElement() ?? "我们先定义 \(topic) 的最小闭环。"
        }
    }

    private func updateSummary(force: Bool) {
        let topic = currentTopic
        let overview = "本次对话围绕“\(topic)”展开，角色分工一发散一收敛。"

        let bullets = [
            "讨论聚焦在 \(topic) 的关键痛点与机会区间。",
            "发散方提出多条可能路径，落地方聚合为 2–3 个可执行步骤。",
            "建议先做最小闭环验证，再扩展到更多场景。"
        ]

        let inspirations = [
            "把 \(topic) 的价值具象为可衡量的时间节省。",
            "用短周期实验建立信心，避免一次性大投入。",
            "把摘要输出做成“可复制的决策痕迹”。"
        ]

        let highlights = messages.suffix(5).map { $0.text }

        summary = SessionSummary(
            title: sessionTitle,
            overview: overview,
            bullets: bullets,
            inspirations: inspirations,
            highlights: highlights
        )
    }

    private func loadHistoryIfNeeded() {
        guard !hasLoadedHistory else { return }
        hasLoadedHistory = true
        history = loadHistoryFromDisk()
        history = filteredHistory(history)
    }

    private func saveSessionToHistory() {
        guard let start = sessionStart, let end = sessionEnd else { return }
        guard !messages.isEmpty else { return }
        let summaryRecord = SessionSummaryRecord(
            title: summary.title,
            overview: summary.overview,
            bullets: summary.bullets,
            inspirations: summary.inspirations,
            highlights: summary.highlights
        )
        let storedMessages: [MessageRecord]
        if saveFullTranscript {
            storedMessages = messages.map { message in
                MessageRecord(id: message.id, role: message.role, text: message.text, time: message.time)
            }
        } else {
            storedMessages = []
        }

        let record = SessionRecord(
            id: UUID(),
            start: start,
            end: end,
            topic: currentTopic,
            summary: summaryRecord,
            messages: storedMessages
        )
        history.insert(record, at: 0)
        history = filteredHistory(history)
        persistHistory()
    }

    private func filteredHistory(_ records: [SessionRecord]) -> [SessionRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -historyRetentionDays, to: Date()) ?? .distantPast
        let filteredByDate = records.filter { $0.end >= cutoffDate }
        return Array(filteredByDate.prefix(maxHistoryCount))
    }

    private func persistHistory() {
        let url = historyFileURL()
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Failed to save history: \(error.localizedDescription)")
        }
    }

    private func loadHistoryFromDisk() -> [SessionRecord] {
        let url = historyFileURL()
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([SessionRecord].self, from: data)) ?? []
    }

    private func historyFileURL() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let folder = baseURL?.appendingPathComponent("LunchTalkSaver", isDirectory: true)
        if let folder {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            return folder.appendingPathComponent("history.json")
        }
        return URL(fileURLWithPath: "/tmp/LunchTalkSaver.history.json")
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
