import SwiftUI
import WidgetKit

/// Medium widget (360×169 pt on macOS) — gauge + stat cards + cost progress bar.
struct MediumWidgetView: View {
    let entry: UsageEntry
    let snapshot: WidgetSnapshot

    init(entry: UsageEntry) {
        self.entry = entry
        self.snapshot = entry.snapshot
    }

    var body: some View {
        HStack(spacing: 14) {
            // Left: Circular gauge
            VStack(spacing: 4) {
                CircularGaugeView(
                    percentage: snapshot.budgetUsedFraction,
                    centerText: "\(snapshot.budgetUsedPercentage)%",
                    lineWidth: 10
                )
                .frame(width: 80, height: 80)

                HStack(spacing: 3) {
                    Circle()
                        .fill(AppTheme.accentCyan)
                        .frame(width: 5, height: 5)
                    Text("DeepSeek")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppTheme.accentCyan)
                }
            }

            // Right: Stats
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    // Prompt tokens
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatNumber(snapshot.monthlyUsage.promptTokens))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.accentCyan)
                        Text("输入Tokens")
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.surface)
                    )

                    // Requests
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatNumber(snapshot.monthlyUsage.totalRequests))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.accentYellow)
                        Text("本月请求")
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.surface)
                    )
                }

                // Cost progress bar
                VStack(spacing: 4) {
                    HStack {
                        Text("费用")
                            .font(.system(size: 10))
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("\(snapshot.formattedCost()) / \(snapshot.formattedBudget())")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.surfaceLight)
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        gradient: AppTheme.gaugeGradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * snapshot.budgetUsedFraction, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return n.formatted()
    }
}

#if DEBUG
struct MediumWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        MediumWidgetView(entry: UsageEntry(
            date: Date(),
            snapshot: .placeholder,
            isPlaceholder: false
        ))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        .containerBackground(AppTheme.background, for: .widget)
    }
}
#endif
