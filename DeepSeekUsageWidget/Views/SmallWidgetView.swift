import SwiftUI
import WidgetKit

/// Small widget (169×169 pt on macOS) — circular gauge + cost + branding.
struct SmallWidgetView: View {
    let entry: UsageEntry

    var body: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)

            CircularGaugeView(
                percentage: entry.snapshot.budgetUsedFraction,
                centerText: "\(entry.snapshot.budgetUsedPercentage)%",
                subtitle: "已用额度",
                lineWidth: 12
            )
            .frame(width: 100, height: 100)

            Spacer(minLength: 6)

            Text(entry.snapshot.formattedCost())
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)

            Text("本月费用")
                .font(.system(size: 9))
                .foregroundColor(AppTheme.textMuted)

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Circle()
                    .fill(AppTheme.accentCyan)
                    .frame(width: 6, height: 6)
                Text("DeepSeek")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.accentCyan)
            }

            Spacer(minLength: 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
