import SwiftUI

/// Simplified view for Screen Saver bundle - no App-only dependencies
struct SaverContentView: View {
    @ObservedObject var store: SessionStore
    @State private var breathing = false

    var body: some View {
        ZStack {
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
                    .scaleEffect(breathing ? 1.08 : 0.94)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.blue.opacity(0.16))
                    .frame(width: 520, height: 520)
                    .blur(radius: 80)
                    .offset(x: 140, y: 180)
                    .scaleEffect(breathing ? 0.95 : 1.08)
            }

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LunchTalk Saver v2")
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(store.sessionTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Circle()
                            .fill(store.isRunning ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(store.isRunning ? "对话中" : "已停止")
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

                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 14) {
                        ForEach(Array(store.messages.suffix(8))) { message in
                            SaverBubbleView(message: message, store: store)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    }
                    .clipped()

                    if store.showSummaryInSaver {
                        SaverSummaryPanel(summary: store.summary)
                            .frame(maxWidth: 340)
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                breathing = true
            }
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
                Spacer(minLength: 46)
            } else {
                Spacer(minLength: 46)
                bubbleContent
            }
        }
    }

    private var bubbleContent: some View {
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
        VStack(alignment: .leading, spacing: 14) {
            Text("实时摘要")
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            if !summary.overview.isEmpty {
                Text(summary.overview)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.82))
            }

            SaverSummarySection(title: "要点", items: summary.bullets)
            SaverSummarySection(title: "灵感点", items: summary.inspirations)

            if !summary.highlights.isEmpty {
                SaverSummarySection(title: "高亮金句", items: summary.highlights)
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

struct SaverSummarySection: View {
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
