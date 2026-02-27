import AppKit
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.openWindow) private var openWindow

    @State private var selection: UUID?

    var body: some View {
        ZStack {
            // Dark space background
            Color(red: 0.024, green: 0.031, blue: 0.063).ignoresSafeArea()

            HStack(spacing: 0) {
                // Left sidebar
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(red: 0.29, green: 0.48, blue: 0.96))
                        Text("历史记录")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider()
                        .overlay(Color.white.opacity(0.1))

                    // List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(store.history) { record in
                                HistoryListItem(
                                    record: record,
                                    isSelected: selection == record.id,
                                    onTap: { selection = record.id }
                                )
                            }
                        }
                        .padding(12)
                    }
                }
                .frame(width: 280)
                .background(.white.opacity(0.03))

                Divider()
                    .overlay(Color.white.opacity(0.1))

                // Detail view
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let record = selectedRecord {
                            HistoryDetailView(record: record, store: store, openWindow: openWindow)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundStyle(.white.opacity(0.3))
                                Text("选择一条历史记录查看详情")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(40)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }
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
}

// MARK: - List Item

private struct HistoryListItem: View {
    let record: SessionRecord
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Left indicator bar
                Rectangle()
                    .fill(colorForRecord)
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 1.5))

                VStack(alignment: .leading, spacing: 6) {
                    Text(record.summary.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(dateText, systemImage: "calendar")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))

                        Label(durationText, systemImage: "timer")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.leading, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.white.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var colorForRecord: Color {
        if Calendar.current.isDateInToday(record.start) {
            return Color(red: 0.29, green: 0.48, blue: 0.96)
        }
        if Calendar.current.isDateInYesterday(record.start) {
            return Color(red: 0.72, green: 0.40, blue: 0.85)
        }
        return Color.gray.opacity(0.5)
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: record.start)
    }

    private var durationText: String {
        let interval = record.end.timeIntervalSince(record.start)
        let minutes = Int(interval / 60)
        return "\(minutes)分"
    }
}

// MARK: - Detail View

private struct HistoryDetailView: View {
    let record: SessionRecord
    @ObservedObject var store: SessionStore
    let openWindow: OpenWindowAction

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Title section
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.4), lineWidth: 1))
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(red: 0.29, green: 0.48, blue: 0.96))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(record.summary.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(fullDateText)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Overview
            if !record.summary.overview.isEmpty {
                Text(record.summary.overview)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(12)
                    .background(.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Summary sections
            HistoryFutureSummarySection(
                title: "摘要",
                items: record.summary.bullets,
                accentColor: Color(red: 0.29, green: 0.48, blue: 0.96),
                icon: "doc.text"
            )

            HistoryFutureSummarySection(
                title: "灵感点",
                items: record.summary.inspirations,
                accentColor: Color(red: 1.0, green: 0.65, blue: 0.1),
                icon: "lightbulb.fill"
            )

            if !record.summary.highlights.isEmpty {
                HistoryFutureSummarySection(
                    title: "高亮金句",
                    items: record.summary.highlights,
                    accentColor: Color(red: 0.72, green: 0.35, blue: 0.95),
                    icon: "quote.bubble.fill"
                )
            }

            Divider()
                .overlay(Color.white.opacity(0.1))
                .padding(.vertical, 4)

            // Full transcript
            if record.messages.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.white.opacity(0.5))
                    Text("未保存完整对话，请在设置中开启\"保存完整对话\"。")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(12)
                .background(.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("完整对话")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    LazyVStack(spacing: 10) {
                        ForEach(record.messages) { message in
                            HistoryBubbleView(message: message, roleAName: store.roleAName, roleBName: store.roleBName)
                        }
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: { copySummary(for: record) }) {
                    Label("复制摘要", systemImage: "doc.on.clipboard")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: { openWindow(id: "main") }) {
                    Label("打开主屏", systemImage: "rectangle.inset.filled")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(red: 0.29, green: 0.48, blue: 0.96))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.3), radius: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
        }
    }

    private var fullDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: record.start)
    }

    private func copySummary(for record: SessionRecord) {
        let summaryText = [
            record.summary.title,
            record.summary.overview,
            record.summary.bullets.map { "• \($0)" }.joined(separator: "\n"),
            record.summary.inspirations.map { "• \($0)" }.joined(separator: "\n")
        ]
        .filter { !$0.isEmpty }
        .joined(separator: "\n\n")

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(summaryText, forType: .string)
    }
}

// MARK: - History Summary Section

private struct HistoryFutureSummarySection: View {
    let title: String
    let items: [String]
    let accentColor: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentColor.opacity(0.7))
                            .frame(width: 2, height: 12)
                            .padding(.top, 2)
                        Text(item)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(12)
        .background(accentColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - History Bubble

private struct HistoryBubbleView: View {
    let message: MessageRecord
    let roleAName: String
    let roleBName: String

    private var isExplorer: Bool { message.role == .explorer }
    private var accentColor: Color { isExplorer ? Color(red: 0.29, green: 0.48, blue: 0.96) : Color(red: 0.00, green: 0.79, blue: 0.63) }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isExplorer {
                avatarView
                bubbleContent
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubbleContent
                avatarView
            }
        }
    }

    private var avatarView: some View {
        let name = isExplorer ? roleAName : roleBName
        let initial = String(name.prefix(1)).uppercased()
        return ZStack {
            Circle()
                .fill(accentColor.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(accentColor.opacity(0.4), lineWidth: 1))
            Text(initial)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var bubbleContent: some View {
        VStack(alignment: isExplorer ? .leading : .trailing, spacing: 6) {
            HStack(spacing: 6) {
                Text(nameForRole)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor.opacity(0.8))

                Text(message.role.badgeText)
                    .font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.15))
                    .clipShape(Capsule())
                    .foregroundStyle(accentColor.opacity(0.9))
            }

            Text(message.text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .frame(maxWidth: 480, alignment: isExplorer ? .leading : .trailing)
    }

    private var nameForRole: String {
        isExplorer ? roleAName : roleBName
    }
}
