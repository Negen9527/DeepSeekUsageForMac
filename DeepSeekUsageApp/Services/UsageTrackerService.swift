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

    /// Load usage history from the App Group shared container.
    func loadHistory() -> [WidgetSnapshot.DailyPoint] {
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        return (try? JSONDecoder().decode([WidgetSnapshot.DailyPoint].self, from: data)) ?? []
    }

    /// Save usage history to the App Group shared container.
    func saveHistory(_ points: [WidgetSnapshot.DailyPoint]) {
        guard let data = try? JSONEncoder().encode(points) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Record today's usage. If today exists in history, increment; otherwise append.
    func recordDailyUsage(tokens: Int, requests: Int, cost: Double) {
        var history = loadHistory()
        let today = dailyKey(for: Date())

        if let index = history.firstIndex(where: { $0.dateString == today }) {
            let existing = history[index]
            history[index] = WidgetSnapshot.DailyPoint(
                dateString: today,
                tokens: existing.tokens + tokens,
                requests: existing.requests + requests,
                cost: existing.cost + cost
            )
        } else {
            history.append(WidgetSnapshot.DailyPoint(
                dateString: today,
                tokens: tokens,
                requests: requests,
                cost: cost
            ))
        }

        // Keep only last 90 days
        if history.count > 90 {
            history = Array(history.suffix(90))
        }
        saveHistory(history)
    }

    /// Get the last 7 days of usage for the trend chart.
    func last7Days() -> [WidgetSnapshot.DailyPoint] {
        let history = loadHistory()
        let keys = (0..<7).map { dailyKey(for: Calendar.current.date(byAdding: .day, value: -$0, to: Date())! ) }
        let lookup = Dictionary(uniqueKeysWithValues: history.map { ($0.dateString, $0) })
        return keys.reversed().map { day in
            lookup[day] ?? WidgetSnapshot.DailyPoint(dateString: day, tokens: 0, requests: 0, cost: 0)
        }
    }

    // MARK: - Monthly Aggregation

    func currentMonthUsage() -> (promptTokens: Int, completionTokens: Int, totalRequests: Int, estimatedCost: Double) {
        let history = loadHistory()
        let thisMonth = monthKey(for: Date())
        let monthPoints = history.filter { monthKey(for: dateFromKey($0.dateString)) == thisMonth }

        let totalTokens = monthPoints.reduce(0) { $0 + $1.tokens }
        let promptTokens = Int(Double(totalTokens) * 0.7) // Estimate 70/30 split
        let completionTokens = totalTokens - promptTokens
        let totalRequests = monthPoints.reduce(0) { $0 + $1.requests }
        let estimatedCost = monthPoints.reduce(0.0) { $0 + $1.cost }

        return (promptTokens, completionTokens, totalRequests, estimatedCost)
    }

    // MARK: - Snapshot

    /// Build a WidgetSnapshot and write it to shared UserDefaults for the widget to read.
    func buildAndWriteSnapshot(balance: BalanceInfo?, monthlyBudget: Double) {
        let monthly = currentMonthUsage()

        let snapshot = WidgetSnapshot(
            lastUpdated: Date(),
            balance: WidgetSnapshot.BalanceSnapshot(
                currency: balance?.currency ?? "CNY",
                totalBalance: balance?.totalBalance ?? 0,
                grantedBalance: balance?.grantedBalance ?? 0,
                toppedUpBalance: balance?.toppedUpBalance ?? 0,
                isAvailable: balance?.isAvailable ?? false
            ),
            monthlyUsage: WidgetSnapshot.MonthlyUsageSnapshot(
                promptTokens: monthly.promptTokens,
                completionTokens: monthly.completionTokens,
                totalRequests: monthly.totalRequests,
                estimatedCost: monthly.estimatedCost,
                monthlyBudget: monthlyBudget
            ),
            trend: last7Days()
        )

        if let data = try? JSONEncoder().encode(snapshot) {
            defaults?.set(data, forKey: AppConstants.snapshotKey)
        }
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
