import SwiftUI

// MARK: - BackgroundView (Dynamic Aurora Background)
struct BackgroundView: View {
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                // Pure black base
                Color.black.ignoresSafeArea()

                // Aurora Glow 1 — Blue-Purple
                EllipticalGradient(
                    colors: [Color(red:0.2, green:0.1, blue:0.8).opacity(0.35), .clear],
                    center: UnitPoint(
                        x: 0.3 + 0.15 * sin(t * 0.23),
                        y: 0.25 + 0.12 * cos(t * 0.17)
                    ),
                    endRadiusFraction: 0.55
                )

                // Aurora Glow 2 — Cyan-Blue
                EllipticalGradient(
                    colors: [Color(red:0.0, green:0.5, blue:0.9).opacity(0.25), .clear],
                    center: UnitPoint(
                        x: 0.7 + 0.12 * cos(t * 0.19),
                        y: 0.6 + 0.15 * sin(t * 0.13)
                    ),
                    endRadiusFraction: 0.5
                )

                // Aurora Glow 3 — Rose-Purple
                EllipticalGradient(
                    colors: [Color(red:0.6, green:0.1, blue:0.5).opacity(0.2), .clear],
                    center: UnitPoint(
                        x: 0.5 + 0.18 * sin(t * 0.11),
                        y: 0.8 + 0.1 * cos(t * 0.21)
                    ),
                    endRadiusFraction: 0.45
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - GlassCard (Reusable Liquid Glass Component)
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                if #available(macOS 26.0, *) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.25), .white.opacity(0.05)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }
            }
    }
}

// MARK: - NeonBorder (Neon Glow Border Modifier)
struct NeonBorder: ViewModifier {
    var color: Color = Color(red: 0.3, green: 0.6, blue: 1.0)
    var cornerRadius: CGFloat = 20
    var lineWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.2), color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
                    .shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 0)
            )
    }
}

extension View {
    func neonBorder(color: Color = Color(red:0.3,green:0.6,blue:1.0), cornerRadius: CGFloat = 20) -> some View {
        modifier(NeonBorder(color: color, cornerRadius: cornerRadius))
    }
}

// MARK: - ThinkingDotsView (Animated Dots for "思考中…")
struct ThinkingDotsView: View {
    var color: Color = .white
    @State private var animating = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? 1.2 : 0.6)
                    .opacity(animating ? 1.0 : 0.3)
                    .shadow(color: color.opacity(0.8), radius: animating ? 4 : 0)
                    .animation(
                        .easeInOut(duration: 0.55)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.18),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - GlassButtonStyle (Glass Button Style)
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.6 : 0.9))
            .frame(width: 36, height: 36)
            .background {
                if #available(macOS 26.0, *) {
                    Circle()
                        .fill(.clear)
                        .glassEffect(.regular, in: Circle())
                } else {
                    Circle()
                        .fill(.white.opacity(configuration.isPressed ? 0.1 : 0.15))
                }
            }
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - OutlineButtonStyle (Outline Button Style)
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.5 : 0.75))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - PrimaryDestructiveButtonStyle (Primary Destructive Button Style)
struct PrimaryDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(red:0.85,green:0.2,blue:0.3), Color(red:0.6,green:0.1,blue:0.4)],
                    startPoint: .leading, endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .shadow(color: Color(red:0.8,green:0.15,blue:0.25).opacity(configuration.isPressed ? 0 : 0.5), radius: 8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - FutureSummarySection (Futuristic Summary Section)
struct FutureSummarySection: View {
    let title: String
    let items: [String]
    let accentColor: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                        .shadow(color: accentColor.opacity(0.5), radius: 4)

                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 3, height: 14)
                            .shadow(color: accentColor.opacity(0.6), radius: 2)
                            .padding(.top, 3)

                        Text(item)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                        .shadow(color: accentColor.opacity(0.3), radius: 6)
                )
        }
    }
}

// MARK: - AuroraBlob (Aurora Blob Component for animated backgrounds)
struct AuroraBlob: View {
    let color: Color
    let size: CGSize
    let offset: CGSize

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: size.width, height: size.height)
            .blur(radius: 100)
            .offset(offset)
    }
}
