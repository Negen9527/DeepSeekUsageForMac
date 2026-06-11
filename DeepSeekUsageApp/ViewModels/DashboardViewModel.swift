import Foundation
import SwiftUI
import Combine
import WidgetKit

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var monthlyBudget: Double = 50.00
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    @Published var isTokenValid = false
    @Published var lastSnapshot: WidgetSnapshot?
    @Published var usageData: UsageData?

    private let keychain = KeychainService()
    private var apiService: DeepSeekAPIService?
    private let tracker = UsageTrackerService()
    private var refreshTimer: AnyCancellable?
    private var token: String?

    init() {
        loadToken()
        loadBudget()
        if isTokenValid {
            writeSnapshot()
            Task { await refresh() }
        }
        startTimer()
    }

    // MARK: - Token

    func loadToken() {
        token = try? keychain.read(key: AppConstants.tokenKeychainKey)
        if let token {
            apiService = DeepSeekAPIService(token: token)
            isTokenValid = true
        }
    }

    func saveToken(_ newToken: String) async -> Bool {
        do {
            let service = DeepSeekAPIService(token: newToken)
            let valid = try await service.validateToken()
            if valid {
                try keychain.save(key: AppConstants.tokenKeychainKey, value: newToken)
                self.token = newToken
                self.apiService = service
                self.isTokenValid = true
                self.errorMessage = nil
                await refresh()
                return true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }

    func clearToken() {
        try? keychain.delete(key: AppConstants.tokenKeychainKey)
        token = nil
        apiService = nil
        isTokenValid = false
        usageData = nil
        writeSnapshot()
    }

    // MARK: - Budget

    func loadBudget() {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        let stored = defaults?.double(forKey: AppConstants.monthlyBudgetKey)
        if let stored, stored > 0 {
            monthlyBudget = stored
        } else {
            monthlyBudget = 50.00
            defaults?.set(monthlyBudget, forKey: AppConstants.monthlyBudgetKey)
        }
    }

    func setBudget(_ value: Double) {
        monthlyBudget = value
        UserDefaults(suiteName: AppConstants.appGroupID)?.set(value, forKey: AppConstants.monthlyBudgetKey)
        writeSnapshot()
    }

    // MARK: - Data Refresh

    func refresh() async {
        guard let apiService else {
            writeSnapshot()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let now = Date()
            let calendar = Calendar.current
            let month = calendar.component(.month, from: now)
            let year = calendar.component(.year, from: now)

            let data = try await apiService.fetchUsage(month: month, year: year)
            usageData = data
            lastUpdated = Date()

            // Record today's usage to local history
            tracker.recordDailyUsage(
                tokens: data.totalTokens,
                requests: data.totalRequests,
                cost: data.totalCost
            )
            writeSnapshot()
        } catch {
            errorMessage = error.localizedDescription
            if case APIError.unauthorized = error {
                isTokenValid = false
            }
            writeSnapshot()
        }

        isLoading = false
    }

    // MARK: - Snapshot

    private func writeSnapshot() {
        tracker.buildAndWriteSnapshot(
            usageData: usageData,
            monthlyBudget: monthlyBudget
        )
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Timer

    private func startTimer() {
        refreshTimer = Timer.publish(every: AppConstants.refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.refresh()
                }
            }
    }
}
