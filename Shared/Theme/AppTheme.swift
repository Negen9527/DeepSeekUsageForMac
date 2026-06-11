import SwiftUI

enum AppTheme {
    // Primary backgrounds
    static let background     = Color(red: 15/255,  green: 23/255,  blue: 30/255)
    static let surface        = Color(red: 22/255,  green: 32/255,  blue: 42/255)
    static let surfaceLight   = Color(red: 30/255,  green: 42/255,  blue: 54/255)
    static let surfaceElevated = Color(red: 35/255, green: 47/255,  blue: 58/255)

    // Accents
    static let accentCyan     = Color(red: 0,        green: 242/255, blue: 255/255)
    static let accentYellow   = Color(red: 255/255,  green: 186/255, blue: 31/255)
    static let accentGreen    = Color(red: 20/255,   green: 164/255, blue: 117/255)
    static let accentRed      = Color(red: 255/255,  green: 82/255,  blue: 82/255)
    static let accentOrange   = Color(red: 255/255,  green: 149/255, blue: 0/255)

    // Text
    static let textPrimary    = Color.white
    static let textSecondary  = Color.white.opacity(0.6)
    static let textMuted      = Color.white.opacity(0.35)

    // Gradients
    static let gaugeGradient = Gradient(colors: [
        accentGreen,
        Color(red: 120/255, green: 220/255, blue: 80/255),
        accentYellow,
        accentOrange,
        accentRed
    ])

    static let cyanGradient = LinearGradient(
        colors: [accentCyan, accentCyan.opacity(0.6)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // SF Symbol helpers
    static let iconBalance   = "yensign.circle.fill"
    static let iconTokens    = "text.word.spacing"
    static let iconRequests  = "arrow.left.arrow.right.circle.fill"
    static let iconCost      = "creditcard.fill"
    static let iconTrend     = "chart.bar.fill"
    static let iconSettings  = "gearshape.fill"
    static let iconRefresh   = "arrow.clockwise"
    static let iconCheckmark = "checkmark.circle.fill"
    static let iconWarning   = "exclamationmark.triangle.fill"
}
