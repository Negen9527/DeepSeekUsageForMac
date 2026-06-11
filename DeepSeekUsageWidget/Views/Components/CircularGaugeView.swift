import SwiftUI

/// A circular ring gauge showing a percentage value with track and gradient fill.
/// The foreground arc animates from 0 to the target percentage on appear.
struct CircularGaugeView: View {
    let percentage: Double // 0.0 ... 1.0
    let centerText: String
    let subtitle: String?
    let lineWidth: CGFloat
    let gradient: Gradient

    @State private var animatedTrim: CGFloat = 0

    init(
        percentage: Double,
        centerText: String,
        subtitle: String? = nil,
        lineWidth: CGFloat = 12,
        gradient: Gradient? = nil
    ) {
        self.percentage = min(max(percentage, 0), 1)
        self.centerText = centerText
        self.subtitle = subtitle
        self.lineWidth = lineWidth
        self.gradient = gradient ?? AppTheme.gaugeGradient
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(AppTheme.surfaceLight, lineWidth: lineWidth)

            // Foreground arc — animated
            Circle()
                .trim(from: 0, to: animatedTrim)
                .stroke(
                    AngularGradient(
                        gradient: gradient,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center text
            VStack(spacing: 2) {
                Text(centerText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedTrim = percentage
            }
        }
        .onChange(of: percentage) { _, newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                animatedTrim = newValue
            }
        }
    }
}

#if DEBUG
struct CircularGaugeView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.background
            CircularGaugeView(
                percentage: 0.72,
                centerText: "72%",
                subtitle: "已用额度",
                lineWidth: 14
            )
            .frame(width: 120, height: 120)
        }
    }
}
#endif
