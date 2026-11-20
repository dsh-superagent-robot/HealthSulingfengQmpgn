import SwiftUI
import UIKit
import SafariServices

// MARK: - Basic building blocks

struct IconButton: View {
    var systemName: String
    var foreground: Color = Theme.textPrimary
    var background: Color = Theme.surface
    var size: CGFloat = 42
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background(background)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScreenHeader: View {
    var eyebrow: String?
    var title: String
    var subtitle: String?
    var trailing: AnyView?
    var leading: AnyView?

    init(eyebrow: String? = nil, title: String, subtitle: String? = nil, leading: AnyView? = nil, trailing: AnyView? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                if let leading { leading }
                VStack(alignment: .leading, spacing: 3) {
                    if let eyebrow {
                        Text(eyebrow.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.4)
                            .foregroundStyle(Theme.accent)
                    }
                    Text(title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer(minLength: 12)
                if let trailing { trailing }
            }
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

struct SectionHeading: View {
    var title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
    }
}

struct StatusPill: View {
    var status: HealthStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(status.color)
                .frame(width: compact ? 5 : 6, height: compact ? 5 : 6)
            Text(status.label)
                .font(.system(size: compact ? 11 : 12, weight: .semibold, design: .rounded))
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 4 : 5)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct TagChip: View {
    var tag: TagDefinition
    var selected: Bool = false
    var showsRemove: Bool = false
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(tag.color.color)
                .frame(width: 7, height: 7)
            Text(tag.name)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            if showsRemove, let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(Theme.textSecondary)
            }
        }
        .foregroundStyle(selected ? .white : Theme.textPrimary)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(selected ? tag.color.color : tag.color.softColor)
        .clipShape(Capsule())
    }
}

struct ProgressBarView: View {
    var progress: Double
    var color: Color = Theme.accent
    var height: CGFloat = 8
    var track: Color = Theme.surfaceAlt

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, min(proxy.size.width * progress, proxy.size.width)))
            }
        }
        .frame(height: height)
    }
}

struct ProgressRing: View {
    var progress: Double
    var color: Color = Theme.accent
    var lineWidth: CGFloat = 8
    var label: String?
    var detail: String?

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                if let label {
                    Text(label)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
                if let detail {
                    Text(detail)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Charts

struct Sparkline: View {
    var values: [Double]
    var color: Color = Theme.accent
    var filled: Bool = true

    var body: some View {
        GeometryReader { proxy in
            let points = normalizedPoints(in: proxy.size)
            ZStack {
                if filled, points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: proxy.size.height))
                        path.addLine(to: points[0])
                        for point in points.dropFirst() { path.addLine(to: point) }
                        path.addLine(to: CGPoint(x: points[points.count - 1].x, y: proxy.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(colors: [color.opacity(0.25), color.opacity(0.01)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                }
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() { path.addLine(to: point) }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else {
            if let value = values.first {
                return [CGPoint(x: size.width / 2, y: size.height / 2)]
            }
            return []
        }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(maxValue - minValue, 0.0001)
        return values.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(values.count - 1)
            let y = size.height - CGFloat((value - minValue) / range) * (size.height - 6) - 3
            return CGPoint(x: x, y: y)
        }
    }
}

struct BarSparkline: View {
    var values: [Double]
    var color: Color = Theme.accent

    var body: some View {
        GeometryReader { proxy in
            let maxValue = max(values.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(color.opacity(0.75))
                        .frame(width: nil, height: max(4, proxy.size.height * CGFloat(value / maxValue)))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: - Decorative

struct LivePulseView: View {
    var bpm: Int
    var color: Color = Theme.accent
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(color.opacity(0.24 - Double(index) * 0.06), lineWidth: 1.5)
                    .scaleEffect(animate ? 1.0 + CGFloat(index) * 0.22 : 0.72)
                    .opacity(animate ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 1.9)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.45),
                        value: animate
                    )
            }
            Circle()
                .fill(
                    RadialGradient(colors: [color.opacity(0.36), color.opacity(0.05)],
                                   center: .center, startRadius: 2, endRadius: 110)
                )
            Image(systemName: "heart.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(color)
                .scaleEffect(animate ? 1.08 : 0.94)
                .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true), value: animate)
            VStack(spacing: 0) {
                Text("\(bpm)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("bpm")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            .offset(y: 110)
        }
        .onAppear { animate = true }
    }
}

struct SoftOrbBackground: View {
    var color: Color = Theme.accent
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 120, y: -220)
            Circle()
                .fill(Theme.teal.opacity(0.1))
                .frame(width: 220, height: 220)
                .blur(radius: 70)
                .offset(x: -150, y: 300)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    var icon: String
    var title: String
    var subtitle: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Theme.accent)
                .frame(width: 76, height: 76)
                .background(Theme.accentSoft)
                .clipShape(Circle())
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 2)
            }
        }
        .padding(26)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Layout helpers

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
            if x + size.width > width && x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: width, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Navigation / tab bar

struct MainTabBar: View {
    @Binding var selection: AppTab
    var onMeasure: () -> Void

    private var leftTabs: [AppTab] { [.home, .dashboard] }
    private var rightTabs: [AppTab] { [.insights, .me] }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(leftTabs) { tab in tabButton(tab) }
            Spacer(minLength: 72)
            ForEach(rightTabs) { tab in tabButton(tab) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .frame(height: 72)
        .background(
            Theme.surface
                .overlay(alignment: .top) { Rectangle().fill(Theme.separator).frame(height: 0.8) }
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Button(action: onMeasure) {
                VStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(Theme.heartGradient)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Theme.background, lineWidth: 5))
                        .shadow(color: Theme.accent.opacity(0.35), radius: 12, x: 0, y: 8)
                    Text("Measure")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                .offset(y: -25)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.easeOut(duration: 0.2)) { selection = tab }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(selection == tab ? Theme.accent : Theme.textTertiary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toast

struct ToastView: View {
    var message: String
    var icon: String = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.green)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Theme.separator.opacity(0.7), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
        .padding(.horizontal, 24)
    }
}

// MARK: - Share sheet / safari

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SafariView: UIViewControllerRepresentable {
    var url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
