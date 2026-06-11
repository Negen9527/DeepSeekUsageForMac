import SwiftUI

/// Menu bar popover content showing a quick summary of usage data.
struct MenuBarContentView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()
                .padding(.horizontal, 12)

            // Content
            if viewModel.isAPIKeyValid, let balance = viewModel.balance {
                dataView(balance: balance)
            } else {
                setupPromptView
            }

            Divider()
                .padding(.horizontal, 12)

            // Footer actions
            footerView
        }
        .frame(width: 300)
        .background(AppTheme.background)
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Circle()
                .fill(AppTheme.accentCyan)
                .frame(width: 10, height: 10)
            Text("DeepSeek 用量")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func dataView(balance: BalanceInfo) -> some View {
        VStack(spacing: 12) {
            // Balance
            VStack(spacing: 4) {
                Text(formattedBalance(balance))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text("剩余余额")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(.top, 4)

            // Quick stats row
            HStack(spacing: 0) {
                quickStat(
                    icon: "arrow.down.circle.fill",
                    value: formatNumber(viewModel.lastSnapshot?.monthlyUsage.promptTokens ?? 0),
                    label: "输入Tokens",
                    color: AppTheme.accentCyan
                )
                Divider()
                    .frame(height: 32)
                quickStat(
                    icon: "arrow.up.circle.fill",
                    value: formatNumber(viewModel.lastSnapshot?.monthlyUsage.completionTokens ?? 0),
                    label: "输出Tokens",
                    color: AppTheme.accentGreen
                )
                Divider()
                    .frame(height: 32)
                quickStat(
                    icon: "number.circle.fill",
                    value: formatNumber(viewModel.lastSnapshot?.monthlyUsage.totalRequests ?? 0),
                    label: "请求数",
                    color: AppTheme.accentYellow
                )
            }
            .padding(.horizontal, 8)

            // Budget bar
            if let snapshot = viewModel.lastSnapshot {
                VStack(spacing: 4) {
                    HStack {
                        Text("月度预算")
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func quickStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var setupPromptView: some View {
        VStack(spacing: 12) {
            Image(systemName: "key.fill")
                .font(.system(size: 28))
                .foregroundColor(AppTheme.textMuted)
                .padding(.top, 8)

            Text("尚未登录")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

            Text("在主窗口中输入 DeepSeek\nAPI Key 以查看用量")
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textMuted)
                .multilineTextAlignment(.center)

            Button("打开主窗口") {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accentCyan)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var footerView: some View {
        HStack {
            if let lastUpdated = viewModel.lastUpdated {
                Text("更新于 \(lastUpdated, style: .time)")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.textMuted)
            }
            Spacer()
            Button("小组件") {
                openWindow(id: "widget")
            }
            .buttonStyle(.link)
            .font(.system(size: 11))
            Button("设置") {
                openWindow(id: "settings")
            }
            .buttonStyle(.link)
            .font(.system(size: 11))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private func formattedBalance(_ balance: BalanceInfo) -> String {
        let symbol = balance.currency == "CNY" ? "¥" : "$"
        return String(format: "%@%.2f", symbol, balance.totalBalance)
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return n.formatted()
    }
}

#if DEBUG
struct MenuBarContentView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarContentView(viewModel: DashboardViewModel())
    }
}
#endif
