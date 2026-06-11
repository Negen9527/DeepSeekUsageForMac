import SwiftUI
import WidgetKit

/// Large widget (360×376 pt on macOS) — stat cards row + usage breakdown + trend chart + cost summary.
struct LargeWidgetView: View {
    let entry: UsageEntry
    let snapshot: WidgetSnapshot
    @State private var useLineChart: Bool = true

    init(entry: UsageEntry) {
        self.entry = entry
        self.snapshot = entry.snapshot
    }

    var body: some View {
        VStack(spacing: 10) {
            // Header
            headerView

            // Row 1: Three stat cards with staggered entrance
            HStack(spacing: 8) {
                StatsCardView(
                    icon: AppTheme.iconBalance,
                    value: snapshot.formattedBalance(),
                    label: "剩余余额",
                    accentColor: AppTheme.accentCyan,
                    delay: 0.0
                )
                StatsCardView(
                    icon: AppTheme.iconTokens,
                    value: formatNumber(snapshot.totalTokens),
                    label: "本月Tokens",
                    accentColor: AppTheme.accentGreen,
                    delay: 0.1
                )
                StatsCardView(
                    icon: AppTheme.iconRequests,
                    value: formatNumber(snapshot.monthlyUsage.totalRequests),
                    label: "本月请求",
                    accentColor: AppTheme.accentYellow,
                    delay: 0.2
                )
            }

            // Row 2: Token distribution — pie chart + progress bars
            VStack(spacing: 8) {
                HStack {
                    Text("用量分布")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                }

                HStack(spacing: 14) {
                    AnimatedPieChartView(
                        promptTokens: snapshot.monthlyUsage.promptTokens,
                        completionTokens: snapshot.monthlyUsage.completionTokens,
                        promptColor: AppTheme.accentCyan,
                        completionColor: AppTheme.accentGreen,
                        size: 80
                    )

                    VStack(spacing: 8) {
                        UsageProgressBar(
                            label: "输入",
                            value: snapshot.monthlyUsage.promptTokens,
                            total: snapshot.totalTokens,
                            tint: AppTheme.accentCyan
                        )
                        UsageProgressBar(
                            label: "输出",
                            value: snapshot.monthlyUsage.completionTokens,
                            total: snapshot.totalTokens,
                            tint: AppTheme.accentGreen
                        )
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.surface)
            )

            // Row 3: 7-day trend chart
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: AppTheme.iconTrend)
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.accentCyan)
                    Text("7日趋势")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Picker("", selection: $useLineChart) {
                        Text("折线").tag(true)
                        Text("柱状").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                    .controlSize(.mini)
                }

                if useLineChart {
                    TrendLineChartView(dataPoints: snapshot.trend, chartHeight: 50)
                } else {
                    TrendChartViewCompact(
                        dataPoints: snapshot.trend,
                        chartHeight: 50,
                        barWidth: 20,
                        spacing: 8
                    )
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.surface)
            )

            // Row 4: Monthly comparison
            VStack(spacing: 6) {
                HStack {
                    Text("月度对比")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("本月 vs 上月")
                        .font(.system(size: 9))
                        .foregroundColor(AppTheme.textMuted)
                }
                HStack(spacing: 10) {
                    comparisonItem(label: "费用",
                                   current: snapshot.comparison.currentMonthCost,
                                   previous: snapshot.comparison.previousMonthCost,
                                   format: { String(format: "¥%.0f", $0) })
                    comparisonItem(label: "Tokens",
                                   current: Double(snapshot.comparison.currentMonthTokens),
                                   previous: Double(snapshot.comparison.previousMonthTokens),
                                   format: { formatNumber(Int($0)) })
                    comparisonItem(label: "请求",
                                   current: Double(snapshot.comparison.currentMonthRequests),
                                   previous: Double(snapshot.comparison.previousMonthRequests),
                                   format: { formatNumber(Int($0)) })
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.surface)
            )

            // Row 5: Cost summary
            VStack(spacing: 4) {
                HStack {
                    Text("总费用")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("\(snapshot.formattedCost()) / \(snapshot.formattedBudget())")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("(\(snapshot.budgetUsedPercentage)%)")
                        .font(.system(size: 10))
                        .foregroundColor(AppTheme.textMuted)
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
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.surface)
            )

            // Row 6: Footer branding + update time
            HStack {
                HStack(spacing: 4) {
                    Circle().fill(AppTheme.accentCyan).frame(width: 6, height: 6)
                    Text("DeepSeek")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.accentCyan)
                }
                Spacer()
                Text(lastUpdatedText)
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Circle()
                .fill(AppTheme.accentCyan)
                .frame(width: 8, height: 8)
            Text("DeepSeek 用量")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.accentCyan)
            Spacer()
            Text(lastUpdatedText)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.textMuted)
        }
    }

    private var lastUpdatedText: String {
        let interval = Date().timeIntervalSince(snapshot.lastUpdated)
        if interval < 60 { return "刚刚更新" }
        if interval < 3600 { return "\(Int(interval / 60))分钟前" }
        return "\(Int(interval / 3600))小时前"
    }

    private func comparisonItem(label: String, current: Double, previous: Double,
                                 format: @escaping (Double) -> String) -> some View {
        let change = previous > 0 ? ((current - previous) / previous * 100) : 0
        let isUp = change >= 0
        return VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(AppTheme.textMuted)
            Text(format(current))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            HStack(spacing: 2) {
                Image(systemName: isUp ? "arrow.up" : "arrow.down")
                    .font(.system(size: 6, weight: .bold))
                Text(String(format: "%.0f%%", abs(change)))
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundColor(isUp ? AppTheme.accentRed : AppTheme.accentGreen)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return n.formatted()
    }
}

#if DEBUG
struct LargeWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        LargeWidgetView(entry: UsageEntry(
            date: Date(),
            snapshot: .placeholder,
            isPlaceholder: false
        ))
        .previewContext(WidgetPreviewContext(family: .systemLarge))
        .containerBackground(AppTheme.background, for: .widget)
    }
}
#endif
