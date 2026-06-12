import SwiftUI

struct DesktopWidgetView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var useLineChart: Bool = true
    @State private var showConfig: Bool = false
    @State private var appeared: Bool = false
    @State private var showAllDays: Bool = false
    @State private var hoveredBalanceIndex: Int?
    @State private var hoveredComparisonIndex: Int?
    @State private var hoveredBudget: Bool = false
    @State private var hoveredTrend: Bool = false

    private var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            if viewModel.isTokenValid {
                contentView
            } else {
                emptyStateView
            }
        }
        .padding(12)
        .background(AppTheme.background)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.isTokenValid)
        .sheet(isPresented: $showConfig) {
            ConfigPanelView(viewModel: viewModel)
        }
        .onAppear { appeared = true }
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    AppTheme.background.opacity(0.75)
                    VStack(spacing: 10) {
                        ProgressView()
                            .scaleEffect(0.9)
                        Text("正在刷新...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AppTheme.accentCyan)
                .frame(width: 8, height: 8)
            Text("DeepSeek 用量")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(AppTheme.accentCyan)

            Spacer()

            if let lastUpdated = viewModel.lastUpdated {
                Text("\(lastUpdated, style: .time)")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textMuted)
            }

            Button(action: {
                Task { @MainActor in
                    let start = Date()
                    await viewModel.refresh()
                    let elapsed = Date().timeIntervalSince(start)
                    if elapsed < 0.7 {
                        try? await Task.sleep(nanoseconds: UInt64((0.7 - elapsed) * 1_000_000_000))
                    }
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: AppTheme.iconRefresh)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .help("刷新")

            Button(action: { showConfig = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textMuted)
            }
            .buttonStyle(.plain)
            .help("配置")
        }
        .padding(.bottom, 8)
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(spacing: 10) {
            statCardsRow
            balanceRow
            trendSection
            comparisonRow
            budgetSection
            footerView
        }
    }

    // MARK: - Stats Cards

    private var statCardsRow: some View {
        HStack(spacing: 8) {
            StatsCardView(icon: AppTheme.iconCost, value: snapshot.formattedCost(),
                          label: "本月费用", accentColor: AppTheme.accentCyan, delay: 0.0)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.0), value: appeared)
            StatsCardView(icon: AppTheme.iconTokens, value: formatNumber(snapshot.totalTokens),
                          label: "本月Tokens", accentColor: AppTheme.accentGreen, delay: 0.1)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)
            StatsCardView(icon: AppTheme.iconRequests, value: formatNumber(snapshot.monthlyUsage.totalRequests),
                          label: "本月请求", accentColor: AppTheme.accentYellow, delay: 0.2)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)
        }
    }

    // MARK: - Balance Row

    private var balanceRow: some View {
        let balance = viewModel.usageData?.balance
        return HStack(spacing: 8) {
            balanceCard(
                icon: "yensign.circle.fill",
                label: "充值余额",
                amount: balance?.normalBalance ?? 0,
                color: AppTheme.accentCyan,
                index: 0
            )
            balanceCard(
                icon: "gift.circle.fill",
                label: "赠送余额",
                amount: balance?.bonusBalance ?? 0,
                color: AppTheme.accentGreen,
                index: 1
            )
            balanceCard(
                icon: "chart.bar.fill",
                label: "可用Tokens",
                amount: Double(balance?.totalTokensEstimation ?? 0),
                color: AppTheme.accentYellow,
                isToken: true,
                index: 2
            )
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.25), value: appeared)
    }

    private func balanceCard(icon: String, label: String, amount: Double, color: Color, isToken: Bool = false, index: Int) -> some View {
        let isHovered = hoveredBalanceIndex == index
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textMuted)
            }
            if isToken {
                Text(formatNumber(Int(amount)))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            } else {
                Text(String(format: "¥%.2f", amount))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(isHovered ? AppTheme.surfaceLight : AppTheme.surface))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(isHovered ? color.opacity(0.3) : .clear, lineWidth: 1))
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .shadow(color: isHovered ? color.opacity(0.12) : .clear, radius: 6)
        .onHover { inside in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hoveredBalanceIndex = inside ? index : nil
            }
        }
    }

    // MARK: - Trend Section

    /// Last 7 calendar days ending today, filled with zeros for missing days.
    private var last7CalendarDays: [WidgetSnapshot.DailyPoint] {
        let allPoints = snapshot.trend
        let lookup = Dictionary(uniqueKeysWithValues: allPoints.map { ($0.dateString, $0) })
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let calendar = Calendar.current
        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: Date())!
            let key = formatter.string(from: date)
            return lookup[key] ?? WidgetSnapshot.DailyPoint(dateString: key, tokens: 0, requests: 0, cost: 0)
        }
    }

    private var trendSection: some View {
        let allPoints = snapshot.trend
        let displayPoints = showAllDays ? allPoints : last7CalendarDays

        return VStack(spacing: 6) {
            HStack {
                Image(systemName: AppTheme.iconTrend).font(.system(size: 10)).foregroundColor(AppTheme.accentCyan)
                Text("\(currentMonth)月用量趋势")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                if allPoints.count > 7 {
                    Button(action: { showAllDays.toggle() }) {
                        Text(showAllDays ? "收起" : "更多")
                            .font(.system(size: 9))
                            .foregroundColor(AppTheme.accentCyan)
                    }
                    .buttonStyle(.plain)
                }
                Picker("", selection: $useLineChart) {
                    Text("折线").tag(true)
                    Text("柱状").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                .controlSize(.mini)
            }
            if useLineChart {
                TrendLineChartView(dataPoints: displayPoints, chartHeight: 50)
            } else {
                TrendChartViewCompact(dataPoints: displayPoints, chartHeight: 50, barWidth: 24, spacing: 8)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(hoveredTrend ? AppTheme.surfaceLight : AppTheme.surface))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(hoveredTrend ? AppTheme.accentCyan.opacity(0.2) : .clear, lineWidth: 1))
        .scaleEffect(hoveredTrend ? 1.02 : 1.0)
        .onHover { inside in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hoveredTrend = inside
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: appeared)
    }

    // MARK: - Monthly Comparison

    private var comparisonRow: some View {
        VStack(spacing: 6) {
            HStack {
                Text("月度对比").font(.system(size: 10, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text("本月 vs 上月").font(.system(size: 9)).foregroundColor(AppTheme.textMuted)
            }
            HStack(spacing: 12) {
                comparisonItem(label: "费用", current: snapshot.comparison.currentMonthCost,
                               previous: snapshot.comparison.previousMonthCost,
                               format: { String(format: "¥%.0f", $0) }, index: 0)
                comparisonItem(label: "Tokens", current: Double(snapshot.comparison.currentMonthTokens),
                               previous: Double(snapshot.comparison.previousMonthTokens),
                               format: { formatNumber(Int($0)) }, index: 1)
                comparisonItem(label: "请求", current: Double(snapshot.comparison.currentMonthRequests),
                               previous: Double(snapshot.comparison.previousMonthRequests),
                               format: { formatNumber(Int($0)) }, index: 2)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surface))
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.35), value: appeared)
    }

    private func comparisonItem(label: String, current: Double, previous: Double,
                                 format: @escaping (Double) -> String, index: Int) -> some View {
        let change = previous > 0 ? ((current - previous) / previous * 100) : 0
        let isUp = change >= 0
        let isHovered = hoveredComparisonIndex == index
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
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 6)
            .fill(isHovered ? AppTheme.surfaceLight : .clear))
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .onHover { inside in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hoveredComparisonIndex = inside ? index : nil
            }
        }
    }

    // MARK: - Budget Section

    private var budgetSection: some View {
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
        .background(RoundedRectangle(cornerRadius: 10)
            .fill(hoveredBudget ? AppTheme.surfaceLight : AppTheme.surface))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(hoveredBudget ? AppTheme.accentCyan.opacity(0.2) : .clear, lineWidth: 1))
        .scaleEffect(hoveredBudget ? 1.02 : 1.0)
        .shadow(color: hoveredBudget ? AppTheme.accentCyan.opacity(0.1) : .clear, radius: 6)
        .onHover { inside in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hoveredBudget = inside
            }
        }
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: appeared)
    }

    private var costProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppTheme.surfaceLight).frame(height: 4)
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(gradient: AppTheme.gaugeGradient, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(geo.size.width * snapshot.budgetUsedFraction, 4), height: 4)
                    .animation(.easeInOut(duration: 0.8), value: snapshot.budgetUsedFraction)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Footer

    private var footerView: some View {
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
        .padding(.top, 2)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 40)
            Image(systemName: "gearshape.fill")
                .font(.system(size: 28))
                .foregroundColor(AppTheme.textMuted)
            Text("尚未配置 Token")
                .font(.system(size: 13, weight: .medium))
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
            Spacer().frame(height: 40)
        }
        .frame(width: 300)
    }

    // MARK: - Helpers

    private var snapshot: WidgetSnapshot {
        viewModel.lastSnapshot ?? .placeholder
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000.0) }
        if n >= 10_000 { return String(format: "%.1fk", Double(n) / 1_000.0) }
        if n >= 1_000 { return String(format: "%.1fk", Double(n) / 1_000.0) }
        return n.formatted()
    }
}
