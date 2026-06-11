import SwiftUI

/// A floating desktop widget that mimics WidgetKit appearance without requiring WidgetKit.
/// Supports three size modes: compact, medium, and large.
struct DesktopWidgetView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedSize: WidgetSize = .large
    @State private var useLineChart: Bool = true
    @State private var showConfig: Bool = false

    enum WidgetSize: String, CaseIterable {
        case compact = "紧凑"
        case medium = "中等"
        case large = "完整"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Size selector and title bar
            headerBar

            // Widget content based on selected size
            ScrollView {
                widgetContent
                    .padding(12)
            }
        }
        .frame(minWidth: minWidth, maxWidth: maxWidth, minHeight: minHeight, maxHeight: maxHeight)
        .background(AppTheme.background)
        .sheet(isPresented: $showConfig) {
            ConfigPanelView(viewModel: viewModel)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Circle()
                .fill(AppTheme.accentCyan)
                .frame(width: 8, height: 8)
            Text("DeepSeek 用量")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.accentCyan)

            Spacer()

            Picker("尺寸", selection: $selectedSize) {
                ForEach(WidgetSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .controlSize(.small)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 14, height: 14)
            }

            // Settings button
            Button(action: { showConfig = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textMuted)
            }
            .buttonStyle(.plain)
            .help("配置")

            if let lastUpdated = viewModel.lastUpdated {
                Text("\(lastUpdated, style: .time)")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Widget Content

    @ViewBuilder
    private var widgetContent: some View {
        if viewModel.isTokenValid {
            switch selectedSize {
            case .compact: compactView
            case .medium: mediumView
            case .large: largeView
            }
        } else {
            emptyStateView
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 40)
            Image(systemName: "gearshape.fill")
                .font(.system(size: 36))
                .foregroundColor(AppTheme.textMuted)
            Text("尚未配置 Token")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
            Text("点击右上角设置按钮\n输入你的 DeepSeek 平台 Token")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)
            Button("打开配置") {
                showConfig = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accentCyan)
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Compact

    private var compactView: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            CircularGaugeView(
                percentage: snapshot.budgetUsedFraction,
                centerText: "\(snapshot.budgetUsedPercentage)%",
                subtitle: "已用额度",
                lineWidth: 14
            )
            .frame(width: 120, height: 120)

            Text(snapshot.formattedCost())
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)

            Text("本月费用")
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textMuted)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Circle().fill(AppTheme.accentCyan).frame(width: 6, height: 6)
                Text("DeepSeek").font(.system(size: 11, weight: .bold)).foregroundColor(AppTheme.accentCyan)
            }
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Medium

    private var mediumView: some View {
        HStack(spacing: 16) {
            CircularGaugeView(
                percentage: snapshot.budgetUsedFraction,
                centerText: "\(snapshot.budgetUsedPercentage)%",
                lineWidth: 10
            )
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    miniCard(value: formatNumber(snapshot.monthlyUsage.promptTokens),
                             label: "输入Tokens", color: AppTheme.accentCyan)
                    miniCard(value: formatNumber(snapshot.monthlyUsage.totalRequests),
                             label: "本月请求", color: AppTheme.accentYellow)
                }

                VStack(spacing: 4) {
                    HStack {
                        Text("费用")
                            .font(.system(size: 10)).foregroundColor(AppTheme.textSecondary)
                        Spacer()
                        Text("\(snapshot.formattedCost()) / \(snapshot.formattedBudget())")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    costProgressBar
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func miniCard(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.textMuted)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.surface))
    }

    // MARK: - Large

    private var largeView: some View {
        VStack(spacing: 10) {
            // Row 1: Stats cards
            HStack(spacing: 8) {
                StatsCardView(icon: AppTheme.iconCost, value: snapshot.formattedCost(),
                              label: "本月费用", accentColor: AppTheme.accentCyan, delay: 0.0)
                StatsCardView(icon: AppTheme.iconTokens, value: formatNumber(snapshot.totalTokens),
                              label: "本月Tokens", accentColor: AppTheme.accentGreen, delay: 0.1)
                StatsCardView(icon: AppTheme.iconRequests, value: formatNumber(snapshot.monthlyUsage.totalRequests),
                              label: "本月请求", accentColor: AppTheme.accentYellow, delay: 0.2)
            }

            // Row 2: Token distribution — pie chart + progress bars
            VStack(spacing: 8) {
                HStack {
                    Text("用量分布").font(.system(size: 10, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                    Spacer()
                }
                HStack(spacing: 16) {
                    AnimatedPieChartView(
                        promptTokens: snapshot.monthlyUsage.promptTokens,
                        completionTokens: snapshot.monthlyUsage.completionTokens,
                        promptColor: AppTheme.accentCyan,
                        completionColor: AppTheme.accentGreen,
                        size: 90
                    )
                    VStack(spacing: 8) {
                        UsageProgressBar(label: "输入", value: snapshot.monthlyUsage.promptTokens,
                                         total: snapshot.totalTokens, tint: AppTheme.accentCyan)
                        UsageProgressBar(label: "输出", value: snapshot.monthlyUsage.completionTokens,
                                         total: snapshot.totalTokens, tint: AppTheme.accentGreen)
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surface))

            // Row 3: Trend
            VStack(spacing: 6) {
                HStack {
                    Image(systemName: AppTheme.iconTrend).font(.system(size: 10)).foregroundColor(AppTheme.accentCyan)
                    Text("7日趋势").font(.system(size: 10, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Picker("", selection: $useLineChart) {
                        Text("折线").tag(true)
                        Text("柱状").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                    .controlSize(.mini)
                }
                if useLineChart {
                    TrendLineChartView(dataPoints: snapshot.trend, chartHeight: 50)
                } else {
                    TrendChartViewCompact(dataPoints: snapshot.trend, chartHeight: 50, barWidth: 24, spacing: 8)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surface))

            // Row 4: Monthly comparison
            VStack(spacing: 6) {
                HStack {
                    Text("月度对比").font(.system(size: 10, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("本月 vs 上月").font(.system(size: 9)).foregroundColor(AppTheme.textMuted)
                }
                HStack(spacing: 12) {
                    comparisonItem(label: "费用", current: snapshot.comparison.currentMonthCost,
                                   previous: snapshot.comparison.previousMonthCost,
                                   format: { String(format: "¥%.0f", $0) })
                    comparisonItem(label: "Tokens", current: Double(snapshot.comparison.currentMonthTokens),
                                   previous: Double(snapshot.comparison.previousMonthTokens),
                                   format: { formatNumber(Int($0)) })
                    comparisonItem(label: "请求", current: Double(snapshot.comparison.currentMonthRequests),
                                   previous: Double(snapshot.comparison.previousMonthRequests),
                                   format: { formatNumber(Int($0)) })
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surface))

            // Row 5: Cost
            VStack(spacing: 4) {
                HStack {
                    Text("总费用").font(.system(size: 10)).foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text("\(snapshot.formattedCost()) / \(snapshot.formattedBudget()) (\(snapshot.budgetUsedPercentage)%)")
                        .font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                }
                costProgressBar
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surface))

            // Row 6: Footer
            HStack {
                HStack(spacing: 4) {
                    Circle().fill(AppTheme.accentCyan).frame(width: 6, height: 6)
                    Text("DeepSeek")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppTheme.accentCyan)
                }
                Spacer()
                if let lastUpdated = viewModel.lastUpdated {
                    Text("更新于 \(lastUpdated, style: .time)")
                        .font(.system(size: 9))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            .padding(.horizontal, 2)
            .padding(.top, 2)
        }
    }

    // MARK: - Shared

    private var costProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.surfaceLight).frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(gradient: AppTheme.gaugeGradient, startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * snapshot.budgetUsedFraction, height: 4)
            }
        }
        .frame(height: 4)
    }

    private func comparisonItem(label: String, current: Double, previous: Double,
                                 format: @escaping (Double) -> String) -> some View {
        let change = previous > 0 ? ((current - previous) / previous * 100) : 0
        let isUp = change >= 0
        return VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(AppTheme.textMuted)
            Text(format(current))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            HStack(spacing: 2) {
                Image(systemName: isUp ? "arrow.up" : "arrow.down")
                    .font(.system(size: 7, weight: .bold))
                Text(String(format: "%.0f%%", abs(change)))
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundColor(isUp ? AppTheme.accentRed : AppTheme.accentGreen)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private var snapshot: WidgetSnapshot {
        viewModel.lastSnapshot ?? .placeholder
    }

    private var minWidth: CGFloat {
        switch selectedSize {
        case .compact: return 200
        case .medium:  return 360
        case .large:   return 380
        }
    }

    private var maxWidth: CGFloat {
        switch selectedSize {
        case .compact: return 220
        case .medium:  return 400
        case .large:   return 420
        }
    }

    private var minHeight: CGFloat {
        switch selectedSize {
        case .compact: return 240
        case .medium:  return 180
        case .large:   return 520
        }
    }

    private var maxHeight: CGFloat {
        switch selectedSize {
        case .compact: return 260
        case .medium:  return 200
        case .large:   return 620
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return n.formatted()
    }
}
