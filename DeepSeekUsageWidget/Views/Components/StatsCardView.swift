import SwiftUI

/// A statistics card with an SF Symbol icon, large value, and label.
/// Animated entrance with scale and fade on appear.
struct StatsCardView: View {
    let icon: String
    let value: String
    let label: String
    let accentColor: Color
    let delay: Double

    @State private var isVisible: Bool = false

    init(icon: String, value: String, label: String, accentColor: Color = AppTheme.accentCyan, delay: Double = 0) {
        self.icon = icon
        self.value = value
        self.label = label
        self.accentColor = accentColor
        self.delay = delay
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textMuted)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accentColor.opacity(0.15), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1 : 0.85)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
    }
}

#if DEBUG
struct StatsCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.background
            HStack {
                StatsCardView(icon: "yensign.circle.fill", value: "¥78.00", label: "剩余余额", accentColor: AppTheme.accentCyan)
                StatsCardView(icon: "text.word.spacing", value: "45.2k", label: "本月Tokens", accentColor: AppTheme.accentGreen)
                StatsCardView(icon: "arrow.left.arrow.right", value: "1,247", label: "本月请求", accentColor: AppTheme.accentYellow)
            }
            .padding()
        }
    }
}
#endif
