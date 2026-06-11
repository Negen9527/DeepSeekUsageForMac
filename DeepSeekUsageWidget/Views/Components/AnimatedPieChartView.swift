import SwiftUI

/// Animated donut chart showing prompt vs completion token distribution.
struct AnimatedPieChartView: View {
    let promptTokens: Int
    let completionTokens: Int
    let promptColor: Color
    let completionColor: Color
    let size: CGFloat

    @State private var promptTrim: CGFloat = 0
    @State private var completionTrim: CGFloat = 0

    private var totalTokens: Int { promptTokens + completionTokens }

    private var promptFraction: Double {
        guard totalTokens > 0 else { return 0.5 }
        return Double(promptTokens) / Double(totalTokens)
    }

    private var completionFraction: Double {
        guard totalTokens > 0 else { return 0.5 }
        return Double(completionTokens) / Double(totalTokens)
    }

    private var promptPercent: Int { Int(promptFraction * 100) }
    private var completionPercent: Int { 100 - promptPercent }

    var body: some View {
        VStack(spacing: 10) {
            // Donut chart
            ZStack {
                // Track
                Circle()
                    .stroke(AppTheme.surfaceLight, lineWidth: lineWidth)
                    .frame(width: size, height: size)

                // Prompt segment (starts at top, goes clockwise)
                Circle()
                    .trim(from: 0, to: promptTrim * promptFraction)
                    .stroke(promptColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))

                // Completion segment (continues from where prompt ends)
                Circle()
                    .trim(from: promptTrim * promptFraction, to: promptTrim * promptFraction + completionTrim * completionFraction)
                    .stroke(completionColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 2) {
                    Text(formatNumber(totalTokens))
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("Total")
                        .font(.system(size: size * 0.11))
                        .foregroundColor(AppTheme.textMuted)
                }
            }

            // Legend
            HStack(spacing: 20) {
                legendItem(color: promptColor, label: "输入", percent: promptPercent)
                legendItem(color: completionColor, label: "输出", percent: completionPercent)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                promptTrim = 1
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                completionTrim = 1
            }
        }
        .onChange(of: promptTokens) { _, _ in reAnimate() }
        .onChange(of: completionTokens) { _, _ in reAnimate() }
    }

    private var lineWidth: CGFloat { size * 0.16 }

    private func legendItem(color: Color, label: String, percent: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
            Text("\(percent)%")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    private func reAnimate() {
        promptTrim = 0
        completionTrim = 0
        withAnimation(.easeOut(duration: 0.8)) {
            promptTrim = 1
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            completionTrim = 1
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return n.formatted()
    }
}

#if DEBUG
struct AnimatedPieChartView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.background
            AnimatedPieChartView(
                promptTokens: 32100,
                completionTokens: 13100,
                promptColor: AppTheme.accentCyan,
                completionColor: AppTheme.accentGreen,
                size: 120
            )
        }
        .frame(width: 200, height: 200)
    }
}
#endif
