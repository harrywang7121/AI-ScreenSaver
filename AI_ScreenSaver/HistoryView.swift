import AppKit
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: SessionStore
    @Environment(\.openWindow) private var openWindow

    @State private var selection: UUID?

    var body: some View {
        ZStack {
            // Dark space background
            Color.black.ignoresSafeArea()

            // Subtle aurora
            Ellipse()
                .fill(Color(red: 0.18, green: 0.22, blue: 0.85).opacity(0.12))
                .frame(width: 500, height: 400)
                .blur(radius: 120)
                .offset(x: -150, y: -180)

            HStack(spacing: 0) {
                // Left sidebar
                VStack(spacing: 0) {
                    // Header with icon glow
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.3), .clear],
                                        center: .center,
                                        startRadius: 3,
                                        endRadius: 15
                                    )
                                )
                                .frame(width: 28, height: 28)

                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(red: 0.29, green: 0.48, blue: 0.96))
                                .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.7), radius: 6)
                        }

                        Text("历史记录")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)

                    Divider()
                        .overlay(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    // List
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(store.history) { record in
                                HistoryListItem(
                                    record: record,
                                    isSelected: selection == record.id,
                                    onTap: { selection = record.id }
                                )
                            }
                        }
                        .padding(14)
                    }
                }
                .frame(width: 300)
                .background {
                    if #available(macOS 26.0, *) {
                        Rectangle()
                            .fill(.clear)
                            .glassEffect(.regular, in: Rectangle())
                    } else {
                        Rectangle()
                            .fill(.white.opacity(0.04))
                    }
                }

                Divider()
                    .overlay(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Detail view
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let record = selectedRecord {
                            HistoryDetailView(record: record, store: store, openWindow: openWindow)
                        } else {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [Color.white.opacity(0.1), .clear],
                                                center: .center,
                                                startRadius: 10,
                                                endRadius: 40
                                            )
                                        )
                                        .frame(width: 80, height: 80)

                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 50, weight: .light))
                                        .foregroundStyle(.white.opacity(0.3))
                                }

                                Text("选择一条历史记录查看详情")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(50)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                }
            }
        }
        .frame(minWidth: 950, minHeight: 680)
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
                // Left indicator bar with glow
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [colorForRecord, colorForRecord.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                    .shadow(color: colorForRecord.opacity(0.7), radius: 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text(record.summary.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        Label(dateText, systemImage: "calendar")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))

                        Label(durationText, systemImage: "timer")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.leading, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .background {
            if isSelected {
                if #available(macOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white.opacity(0.1))
                }
            }
        }
        .neonBorder(
            color: isSelected ? Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.6) : .clear,
            cornerRadius: 10
        )
        .shadow(
            color: isSelected ? Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.3) : .clear,
            radius: 8
        )
    }

    private var colorForRecord: Color {
        if Calendar.current.isDateInToday(record.start) {
            return Color(red: 0.29, green: 0.48, blue: 0.96)
        }
        if Calendar.current.isDateInYesterday(record.start) {
            return Color(red: 0.72, green: 0.40, blue: 0.85)
        }
        return Color.gray.opacity(0.6)
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
        VStack(alignment: .leading, spacing: 20) {
            // Title section with glow
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.3), .clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 26
                            )
                        )
                        .frame(width: 46, height: 46)
                        .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.5), radius: 12)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.29, green: 0.48, blue: 0.96),
                                    Color.yellow.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(red: 0.29, green: 0.48, blue: 0.96))
                        .shadow(color: .yellow.opacity(0.6), radius: 6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.summary.title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(fullDateText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            // Overview with glass effect
            if !record.summary.overview.isEmpty {
                Text(record.summary.overview)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineSpacing(4)
                    .padding(15)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.white.opacity(0.12), lineWidth: 1.5)
                            )
                    }
            }

            // Summary sections with futuristic style
            FutureSummarySection(
                title: "摘要",
                items: record.summary.bullets,
                accentColor: Color(red: 0.29, green: 0.48, blue: 0.96),
                icon: "doc.text"
            )

            FutureSummarySection(
                title: "灵感点",
                items: record.summary.inspirations,
                accentColor: Color(red: 1.0, green: 0.65, blue: 0.1),
                icon: "lightbulb.fill"
            )

            if !record.summary.highlights.isEmpty {
                FutureSummarySection(
                    title: "高亮金句",
                    items: record.summary.highlights,
                    accentColor: Color(red: 0.72, green: 0.35, blue: 0.95),
                    icon: "quote.bubble.fill"
                )
            }

            Divider()
                .overlay(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.vertical, 6)

            // Full transcript
            if record.messages.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.white.opacity(0.5))
                    Text("未保存完整对话，请在设置中开启\"保存完整对话\"。")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.65))
                        Text("完整对话")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(record.messages) { message in
                            HistoryBubbleView(
                                message: message,
                                roleAName: store.roleAName,
                                roleBName: store.roleBName
                            )
                        }
                    }
                }
            }

            // Action buttons with futuristic styling
            HStack(spacing: 14) {
                Button(action: { copySummary(for: record) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 13, weight: .bold))
                        Text("复制摘要")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        if #available(macOS 26.0, *) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.clear)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .neonBorder(color: .white.opacity(0.3), cornerRadius: 14)
                }
                .buttonStyle(.plain)

                Button(action: { openWindow(id: "main") }) {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.inset.filled")
                            .font(.system(size: 14, weight: .black))
                        Text("打开主屏")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
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
                    .neonBorder(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.8), cornerRadius: 14)
                    .shadow(color: Color(red: 0.29, green: 0.48, blue: 0.96).opacity(0.5), radius: 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
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

// MARK: - History Bubble

private struct HistoryBubbleView: View {
    let message: MessageRecord
    let roleAName: String
    let roleBName: String

    private var isExplorer: Bool { message.role == .explorer }
    private var accentColor: Color {
        isExplorer ? Color(red: 0.29, green: 0.48, blue: 0.96) : Color(red: 0.00, green: 0.79, blue: 0.63)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isExplorer {
                avatarView
                bubbleContent
                Spacer(minLength: 50)
            } else {
                Spacer(minLength: 50)
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
                .fill(
                    RadialGradient(
                        colors: [accentColor.opacity(0.25), accentColor.opacity(0.12)],
                        center: .center,
                        startRadius: 3,
                        endRadius: 18
                    )
                )
                .frame(width: 36, height: 36)
                .shadow(color: accentColor.opacity(0.5), radius: 6)

            Circle()
                .stroke(accentColor.opacity(0.5), lineWidth: 1.5)
                .frame(width: 36, height: 36)

            Text(initial)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var bubbleContent: some View {
        VStack(alignment: isExplorer ? .leading : .trailing, spacing: 7) {
            HStack(spacing: 7) {
                Text(nameForRole)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor.opacity(0.85))

                Text(message.role.badgeText)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.18))
                            .overlay(
                                Capsule()
                                    .stroke(accentColor.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(accentColor.opacity(0.9))
            }

            Text(message.text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.87))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.25), lineWidth: 1)
                )
        }
        .frame(maxWidth: 500, alignment: isExplorer ? .leading : .trailing)
    }

    private var nameForRole: String {
        isExplorer ? roleAName : roleBName
    }
}
