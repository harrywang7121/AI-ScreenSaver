import SwiftUI

/// Simplified view for Screen Saver bundle - no App-only dependencies
struct SaverContentView: View {
    @ObservedObject var store: SessionStore

    var body: some View {
        ZStack {
            // Background gradient
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
            )
            .overlay(
                RoundedRectangle(cornerRadius: 80)
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 680, height: 420)
                    .offset(x: 260, y: 240)
            )

            VStack(spacing: 20) {
                // Header
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

                    // Running badge
                    HStack(spacing: 8) {
                        Circle()
                            .fill(store.isRunning ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        Text(store.isRunning ? "对话中" : "已停止")
                            .font(.custom("Avenir Next", size: 14))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
                }

                // Chat and summary
                HStack(alignment: .top, spacing: 18) {
                    // Chat list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 18) {
                                ForEach(store.messages) { message in
                                    SaverBubbleView(message: message, store: store)
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

struct SaverBubbleView: View {
    let message: Message
    @ObservedObject var store: SessionStore

    var body: some View {
        HStack {
            if message.role == .explorer {
                bubbleContent
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                bubbleContent
            }
        }
    }

    private var bubbleContent: some View {
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

            Text(message.text)
                .font(.custom("Avenir Next", size: 15))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(Self.timeFormatter.string(from: message.time))
                .font(.custom("Avenir Next", size: 11))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(message.role.bubbleColor.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: 420, alignment: message.role == .explorer ? .leading : .trailing)
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

struct SaverSummaryPanel: View {
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

            SaverSummarySection(title: "要点", items: summary.bullets)
            SaverSummarySection(title: "灵感点", items: summary.inspirations)

            if !summary.highlights.isEmpty {
                SaverSummarySection(title: "高亮金句", items: summary.highlights)
            }

            Spacer()
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct SaverSummarySection: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Avenir Next", size: 13))
                .foregroundStyle(.white.opacity(0.75))

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
