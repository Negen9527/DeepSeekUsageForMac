import Foundation

/// Mirrors the response from GET https://api.deepseek.com/user/balance
struct BalanceResponse: Codable {
    let isAvailable: Bool
    let balanceInfos: [BalanceEntry]
}

struct BalanceEntry: Codable {
    let currency: String
    let totalBalance: String
    let grantedBalance: String
    let toppedUpBalance: String
}

/// Processed balance data ready for display
struct BalanceInfo {
    let isAvailable: Bool
    let currency: String
    let totalBalance: Double
    let grantedBalance: Double
    let toppedUpBalance: Double

    init(from response: BalanceResponse) {
        self.isAvailable = response.isAvailable
        let entry = response.balanceInfos.first
        self.currency = entry?.currency ?? "CNY"
        self.totalBalance = Self.parseDecimal(entry?.totalBalance)
        self.grantedBalance = Self.parseDecimal(entry?.grantedBalance)
        self.toppedUpBalance = Self.parseDecimal(entry?.toppedUpBalance)
    }

    static func placeholder() -> BalanceInfo {
        BalanceInfo(
            isAvailable: true,
            currency: "CNY",
            totalBalance: 78.00,
            grantedBalance: 50.00,
            toppedUpBalance: 28.00
        )
    }

    private init(isAvailable: Bool, currency: String, totalBalance: Double, grantedBalance: Double, toppedUpBalance: Double) {
        self.isAvailable = isAvailable
        self.currency = currency
        self.totalBalance = totalBalance
        self.grantedBalance = grantedBalance
        self.toppedUpBalance = toppedUpBalance
    }

    private static func parseDecimal(_ string: String?) -> Double {
        guard let string else { return 0 }
        return Double(string) ?? 0
    }
}
