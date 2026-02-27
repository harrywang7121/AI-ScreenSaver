import AppKit
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.openWindow) private var openWindow

    @State private var selection: UUID?

    var body: some View {
        HStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(store.history) { record in
                    HStack(spacing: 0) {
                        // 左侧指示条
                        Rectangle()
                            .fill(colorForRecord(record))
                            .frame(width: 4)
                            .clipShape(RoundedRectangle(cornerRadius: 2))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.summary.title)
                                .font(.custom("Avenir Next", size: 14))
                            HStack {
                                Text(Self.dateFormatter.string(from: record.start))
                                    .font(.custom("Avenir Next", size: 11))
                                    .foregroundStyle(.secondary)
                                Text(durationText(for: record))
                                    .font(.custom("Avenir Next", size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.leading, 10)
                        .padding(.vertical, 6)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .tag(record.id)
                }
            }
            .frame(minWidth: 240)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let record = selectedRecord {
                        Text(record.summary.title)
                            .font(.custom("Avenir Next", size: 20))

                        if !record.summary.overview.isEmpty {
                            Text(record.summary.overview)
                                .font(.custom("Avenir Next", size: 13))
                                .foregroundStyle(.secondary)
                        }

                        HistorySection(title: "摘要", items: record.summary.bullets)
                        HistorySection(title: "灵感点", items: record.summary.inspirations)

                        if !record.summary.highlights.isEmpty {
                            HistorySection(title: "高亮金句", items: record.summary.highlights)
                        }

                        Divider()

                        if record.messages.isEmpty {
                            Text("未保存完整对话，请在设置中开启“保存完整对话”。")
                                .font(.custom("Avenir Next", size: 12))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("完整对话")
                                .font(.custom("Avenir Next", size: 14))
                                .foregroundStyle(.secondary)

                            LazyVStack(spacing: 12) {
                                ForEach(record.messages) { message in
                                    HistoryBubbleView(message: message, roleAName: store.roleAName, roleBName: store.roleBName)
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            Button("复制摘要") {
                                copySummary(for: record)
                            }
                            .buttonStyle(.bordered)

                            Button("打开主屏") {
                                openWindow(id: "main")
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text("选择一条历史记录查看详情")
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 900, minHeight: 640)
        .onAppear {
            if selection == nil {
                selection = store.history.first?.id
            }
        }
    }

    private var selectedRecord: SessionRecord? {
        store.history.first { $0.id == selection }
    }

    private func colorForRecord(_ record: SessionRecord) -> Color {
        if Calendar.current.isDateInToday(record.start) {
            return Color(red: 0.24, green: 0.44, blue: 0.92)
        }
        if Calendar.current.isDateInYesterday(record.start) {
            return Color(red: 0.72, green: 0.40, blue: 0.85)
        }
        return Color.gray.opacity(0.5)
    }

    private func durationText(for record: SessionRecord) -> String {
        let interval = record.end.timeIntervalSince(record.start)
        let minutes = Int(interval / 60)
        return "\(minutes) 分钟"
    }

    private func copySummary(for record: SessionRecord) {
        let summaryText = [
            record.summary.title,
            record.summary.overview,
            record.summary.bullets.map { "• \($0)" }.joined(separator: "\n"),
            record.summary.inspirations.map { "• \($0)" }.joined(separator: "\n")
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(summaryText, forType: .string)
        #endif
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter
    }()
}

private struct HistorySection: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Avenir Next", size: 12))
                .foregroundStyle(.secondary)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(Color.secondary.opacity(0.7))
                        .frame(width: 4, height: 4)
                        .padding(.top, 6)
                    Text(item)
                        .font(.custom("Avenir Next", size: 13))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct HistoryBubbleView: View {
    let message: MessageRecord
    let roleAName: String
    let roleBName: String

    var body: some View {
        HStack {
            if message.role == .explorer {
                bubble
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubble
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: message.role == .explorer ? .leading : .trailing, spacing: 6) {
            HStack(spacing: 8) {
                Text(nameForRole)
                    .font(.custom("Avenir Next", size: 12))
                    .foregroundStyle(.secondary)

                Text(message.role.badgeText)
                    .font(.custom("Avenir Next", size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(message.role.backgroundTint.opacity(0.2))
                    .clipShape(Capsule())
            }

            Text(message.text)
                .font(.custom("Avenir Next", size: 14))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(message.role.bubbleColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(maxWidth: 520, alignment: message.role == .explorer ? .leading : .trailing)
    }

    private var nameForRole: String {
        switch message.role {
        case .explorer:
            return roleAName
        case .builder:
            return roleBName
        }
    }
}
