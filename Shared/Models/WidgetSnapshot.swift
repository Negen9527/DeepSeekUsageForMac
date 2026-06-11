import Foundation

/// The serialized payload shared between the host app and widget extension via App Group UserDefaults.
struct WidgetSnapshot: Codable {
    let lastUpdated: Date
    let monthlyUsage: MonthlyUsageSnapshot
    let trend: [DailyPoint]
    let monthlyComparison: MonthlyComparison?

    struct MonthlyUsageSnapshot: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalRequests: Int
        let totalCost: Double
        let monthlyBudget: Double
    }

    struct DailyPoint: Codable {
        let dateString: String
        let tokens: Int
        let requests: Int
        let cost: Double
    }

    struct MonthlyComparison: Codable {
        let currentMonthCost: Double
        let previousMonthCost: Double
        let currentMonthTokens: Int
        let previousMonthTokens: Int
        let currentMonthRequests: Int
        let previousMonthRequests: Int
    }
}

// MARK: - Computed properties

extension WidgetSnapshot {
    var comparison: MonthlyComparison {
        monthlyComparison ?? MonthlyComparison(
            currentMonthCost: monthlyUsage.totalCost,
            previousMonthCost: 0,
            currentMonthTokens: totalTokens,
            previousMonthTokens: 0,
            currentMonthRequests: monthlyUsage.totalRequests,
            previousMonthRequests: 0
        )
    }

    var totalTokens: Int {
        monthlyUsage.promptTokens + monthlyUsage.completionTokens
    }

    var budgetUsedFraction: Double {
        guard monthlyUsage.monthlyBudget > 0 else { return 0 }
        return min(monthlyUsage.totalCost / monthlyUsage.monthlyBudget, 1.0)
    }

    var budgetUsedPercentage: Int {
        Int(budgetUsedFraction * 100)
    }

    var promptFraction: Double {
        guard totalTokens > 0 else { return 0.5 }
        return Double(monthlyUsage.promptTokens) / Double(totalTokens)
    }

    var completionFraction: Double {
        guard totalTokens > 0 else { return 0.5 }
        return Double(monthlyUsage.completionTokens) / Double(totalTokens)
    }
}

// MARK: - Placeholder

extension WidgetSnapshot {
    static var placeholder: WidgetSnapshot {
        WidgetSnapshot(
            lastUpdated: Date(),
            monthlyUsage: MonthlyUsageSnapshot(
                promptTokens: 32100,
                completionTokens: 13100,
                totalRequests: 847,
                totalCost: 34.20,
                monthlyBudget: 50.00
            ),
            trend: [
                DailyPoint(dateString: "周一", tokens: 5800, requests: 120, cost: 4.20),
                DailyPoint(dateString: "周二", tokens: 7200, requests: 145, cost: 5.10),
                DailyPoint(dateString: "周三", tokens: 3100, requests: 88, cost: 2.30),
                DailyPoint(dateString: "周四", tokens: 8900, requests: 156, cost: 6.80),
                DailyPoint(dateString: "周五", tokens: 4200, requests: 102, cost: 3.10),
                DailyPoint(dateString: "周六", tokens: 5100, requests: 115, cost: 3.90),
                DailyPoint(dateString: "周日", tokens: 6500, requests: 121, cost: 4.60)
            ],
            monthlyComparison: MonthlyComparison(
                currentMonthCost: 34.20,
                previousMonthCost: 28.50,
                currentMonthTokens: 45200,
                previousMonthTokens: 38100,
                currentMonthRequests: 847,
                previousMonthRequests: 720
            )
        )
    }
}

// MARK: - Formatting helpers

extension WidgetSnapshot {
    func formattedCost() -> String {
        return String(format: "¥%.2f", monthlyUsage.totalCost)
    }

    func formattedBudget() -> String {
        return String(format: "¥%.2f", monthlyUsage.monthlyBudget)
    }
}

extension WidgetSnapshot.DailyPoint {
    var formattedDate: String { dateString }
}
