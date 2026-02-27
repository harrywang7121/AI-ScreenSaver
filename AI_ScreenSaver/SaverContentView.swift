import SwiftUI

/// Simplified view for Screen Saver bundle - no App-only dependencies
struct SaverContentView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        ZStack {
            // Aurora background
            BackgroundView()

            VStack(spacing: 20) {
                // Header
                SaverHeaderView(store: store)

                // Chat and summary
                HStack(alignment: .top, spacing: 18) {
                    // Chat list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(store.messages) { message in
                                    SaverBubbleView(message: message, store: store)
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
                                .glassEffect(.regular)
                        } else {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }

                    // Summary panel
                    if store.showSummaryInSaver {
                        SaverSummaryPanel(summary: store.summary)
                            .frame(maxWidth: 320)
                    }
                }
            }
            .padding(28)
        }
    }
}

// Background is defined in SharedComponents.swift

// MARK: - Header

private struct SaverHeaderView: View {
    @ObservedObject var store: SessionStore

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

            SaverRunningBadge(isRunning: store.isRunning)
        }
    }
}

private struct SaverRunningBadge: View {
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

// MARK: - Bubble

struct SaverBubbleView: View {
    let message: Message
    @ObservedObject var store: SessionStore
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

// MARK: - Summary Panel

struct SaverSummaryPanel: View {
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
                    .glassEffect(.regular)
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
