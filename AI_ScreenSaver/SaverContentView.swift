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
                            LazyVStack(spacing: 20) {
                                ForEach(store.messages) { message in
                                    SaverBubbleView(message: message, store: store)
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

// MARK: - Header

private struct SaverHeaderView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        HStack(alignment: .top) {
            HStack(spacing: 11) {
                ZStack {
                    // Outer glow
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

                    // Neon ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.29, green: 0.48, blue: 0.96),
                                    Color(red: 0.55, green: 0.20, blue: 0.80)
                                ],
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

            SaverRunningBadge(isRunning: store.isRunning)
        }
    }
}

private struct SaverRunningBadge: View {
    let isRunning: Bool
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                if isRunning {
                    Circle()
                        .fill(Color.green.opacity(0.45))
                        .frame(width: 20, height: 20)
                        .scaleEffect(pulse ? 1.7 : 1.0)
                        .opacity(pulse ? 0 : 0.9)
                        .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
                }
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

// MARK: - Bubble

struct SaverBubbleView: View {
    let message: Message
    @ObservedObject var store: SessionStore
    @State private var appeared = false

    private var isExplorer: Bool { message.role == .explorer }
    private var accentColor: Color { isExplorer ? Color(red: 0.29, green: 0.48, blue: 0.96) : Color(red: 0.00, green: 0.79, blue: 0.63) }

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

// MARK: - Summary Panel

struct SaverSummaryPanel: View {
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
