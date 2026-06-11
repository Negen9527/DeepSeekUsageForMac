import SwiftUI

/// A labeled horizontal progress bar showing a breakdown value vs total.
struct UsageProgressBar: View {
    let label: String
    let value: Int
    let total: Int
    let tint: Color

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(Double(value) / Double(total), 1.0)
    }

    private var percentage: Int { Int(fraction * 100) }

    @State private var animatedFraction: CGFloat = 0

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text(formatNumber(value))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    + Text("  \(percentage)%")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textMuted)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.surfaceLight)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(tint)
                        .frame(width: geo.size.width * animatedFraction, height: 6)
                        .animation(.easeOut(duration: 0.8), value: animatedFraction)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedFraction = fraction
            }
        }
        .onChange(of: fraction) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedFraction = newValue
            }
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 {
            return String(format: "%.1fk", Double(n) / 1000.0)
        } else if n >= 1000 {
            return String(format: "%.1fk", Double(n) / 1000.0)
        }
        return n.formatted()
    }
}

#if DEBUG
struct UsageProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.background
            VStack(spacing: 16) {
                UsageProgressBar(label: "Prompt Tokens", value: 32100, total: 45200, tint: AppTheme.accentCyan)
                UsageProgressBar(label: "Completion Tokens", value: 13100, total: 45200, tint: AppTheme.accentGreen)
            }
            .padding()
        }
    }
}
#endif
