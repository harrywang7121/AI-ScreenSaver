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
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.summary.title)
                            .font(.system(size: 14, weight: .semibold))
                        Text(Self.dateFormatter.string(from: record.start))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .tag(record.id)
                }
            }
            .frame(minWidth: 260)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let record = selectedRecord {
                        Text(record.summary.title)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))

                        if !record.summary.overview.isEmpty {
                            Text(record.summary.overview)
                                .font(.system(size: 13, weight: .regular))
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
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("完整对话")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.secondary)

                            LazyVStack(spacing: 12) {
                                ForEach(record.messages) { message in
                                    HistoryBubbleView(message: message, roleAName: store.roleAName, roleBName: store.roleBName)
                                }
                            }
                        }

                        HStack(spacing: 10) {
                            Button("复制摘要") {
                                copySummary(for: record)
                            }
                            .buttonStyle(.bordered)

                            Button("打开主屏") {
                                openWindow(id: "main")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Text("选择一条历史记录查看详情")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(22)
            }
        }
        .background(.regularMaterial)
        .frame(minWidth: 920, minHeight: 650)
        .onAppear {
            if selection == nil {
                selection = store.history.first?.id
            }
        }
    }

    private var selectedRecord: SessionRecord? {
        store.history.first { $0.id == selection }
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 7) {
                    Circle()
                        .fill(Color.secondary.opacity(0.7))
                        .frame(width: 4, height: 4)
                        .padding(.top, 6)
                    Text(item)
                        .font(.system(size: 13, weight: .regular))
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
                Spacer(minLength: 44)
            } else {
                Spacer(minLength: 44)
                bubble
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: message.role == .explorer ? .leading : .trailing, spacing: 6) {
            HStack(spacing: 8) {
                Text(nameForRole)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(message.role.badgeText)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(message.role.backgroundTint.opacity(0.2))
                    .clipShape(Capsule())
            }

            Text(message.text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            message.role == .explorer ? Color.secondary.opacity(0.08) : Color.accentColor.opacity(0.12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(maxWidth: 560, alignment: message.role == .explorer ? .leading : .trailing)
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
