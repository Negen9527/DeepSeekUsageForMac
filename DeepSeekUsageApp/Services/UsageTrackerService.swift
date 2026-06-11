import Foundation

/// Manages local usage history and builds widget snapshots for the widget extension.
final class UsageTrackerService {
    private let fileURL: URL
    private let defaults = UserDefaults(suiteName: AppConstants.appGroupID)

    init() {
        self.fileURL = AppConstants.historyFileURL
        ensureDirectoryExists()
    }

    // MARK: - History

    func loadHistory() -> [WidgetSnapshot.DailyPoint] {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        return (try? JSONDecoder().decode([WidgetSnapshot.DailyPoint].self, from: data)) ?? []
    }

    func saveHistory(_ points: [WidgetSnapshot.DailyPoint]) {
        guard let data = try? JSONEncoder().encode(points) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Record today's usage. Overwrites today's entry with the latest API value each refresh.
    func recordDailyUsage(tokens: Int, requests: Int, cost: Double) {
        var history = loadHistory()
        let today = dailyKey(for: Date())

        if let index = history.firstIndex(where: { $0.dateString == today }) {
            history[index] = WidgetSnapshot.DailyPoint(
                dateString: today,
                tokens: tokens,
                requests: requests,
                cost: cost
            )
        } else {
            history.append(WidgetSnapshot.DailyPoint(
                dateString: today,
                tokens: tokens,
                requests: requests,
                cost: cost
            ))
        }

        if history.count > 90 {
            history = Array(history.suffix(90))
        }
        saveHistory(history)
    }

    /// Get the last 7 days of usage for the trend chart.
    func last7Days() -> [WidgetSnapshot.DailyPoint] {
        let history = loadHistory()
        let keys = (0..<7).map { dailyKey(for: Calendar.current.date(byAdding: .day, value: -$0, to: Date())!) }
        let lookup = Dictionary(uniqueKeysWithValues: history.map { ($0.dateString, $0) })
        return keys.reversed().map { day in
            lookup[day] ?? WidgetSnapshot.DailyPoint(dateString: day, tokens: 0, requests: 0, cost: 0)
        }
    }

    // MARK: - Monthly Aggregation

    func currentMonthUsage() -> (promptTokens: Int, completionTokens: Int, totalRequests: Int, totalCost: Double) {
        let history = loadHistory()
        let thisMonth = monthKey(for: Date())
        let monthPoints = history.filter { monthKey(for: dateFromKey($0.dateString)) == thisMonth }

        let totalTokens = monthPoints.reduce(0) { $0 + $1.tokens }
        let promptTokens = Int(Double(totalTokens) * 0.7)
        let completionTokens = totalTokens - promptTokens
        let totalRequests = monthPoints.reduce(0) { $0 + $1.requests }
        let totalCost = monthPoints.reduce(0.0) { $0 + $1.cost }

        return (promptTokens, completionTokens, totalRequests, totalCost)
    }

    func lastMonthUsage() -> (tokens: Int, requests: Int, cost: Double) {
        let history = loadHistory()
        let calendar = Calendar.current
        guard let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return (0, 0, 0)
        }
        let lastMonthKey = monthKey(for: lastMonth)
        let monthPoints = history.filter { monthKey(for: dateFromKey($0.dateString)) == lastMonthKey }

        let tokens = monthPoints.reduce(0) { $0 + $1.tokens }
        let requests = monthPoints.reduce(0) { $0 + $1.requests }
        let cost = monthPoints.reduce(0.0) { $0 + $1.cost }

        return (tokens, requests, cost)
    }

    // MARK: - Snapshot

    func buildAndWriteSnapshot(usageData: UsageData?, monthlyBudget: Double) -> WidgetSnapshot {
        let monthly = usageData ?? UsageData(
            promptTokens: 0, completionTokens: 0, totalRequests: 0, totalCost: 0
        )
        let lastMonth = lastMonthUsage()

        let snapshot = WidgetSnapshot(
            lastUpdated: Date(),
            monthlyUsage: WidgetSnapshot.MonthlyUsageSnapshot(
                promptTokens: monthly.promptTokens,
                completionTokens: monthly.completionTokens,
                totalRequests: monthly.totalRequests,
                totalCost: monthly.totalCost,
                monthlyBudget: monthlyBudget
            ),
            trend: last7Days(),
            monthlyComparison: WidgetSnapshot.MonthlyComparison(
                currentMonthCost: monthly.totalCost,
                previousMonthCost: lastMonth.cost,
                currentMonthTokens: monthly.totalTokens,
                previousMonthTokens: lastMonth.tokens,
                currentMonthRequests: monthly.totalRequests,
                previousMonthRequests: lastMonth.requests
            )
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            defaults?.set(data, forKey: AppConstants.snapshotKey)
        }
        return snapshot
    }
}

// MARK: - Date helpers

private func dailyKey(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    return formatter.string(from: date)
}

private func monthKey(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM"
    return formatter.string(from: date)
}

private func dateFromKey(_ key: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd"
    let currentYear = Calendar.current.component(.year, from: Date())
    return formatter.date(from: key)
        .flatMap { Calendar.current.date(bySetting: .year, value: currentYear, of: $0) }
        ?? Date()
}

// MARK: - Helpers

private func ensureDirectoryExists() {
    let dir = AppConstants.appGroupContainer
    if !FileManager.default.fileExists(atPath: dir.path) {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
}
