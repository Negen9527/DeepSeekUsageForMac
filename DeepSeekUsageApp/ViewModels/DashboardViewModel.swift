import Foundation
import SwiftUI
import Combine
import WidgetKit

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var balance: BalanceInfo?
    @Published var monthlyBudget: Double = 50.00
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    @Published var isAPIKeyValid = false

    private let keychain = KeychainService()
    private var apiService: DeepSeekAPIService?
    private let tracker = UsageTrackerService()
    private var refreshTimer: AnyCancellable?
    private var apiKey: String?

    // Cache snapshot data for direct widget reads in case of issues
    @Published var lastSnapshot: WidgetSnapshot?

    init() {
        loadAPIKey()
        loadBudget()
        if isAPIKeyValid {
            Task { await refresh() }
        }
        startTimer()
    }

    // MARK: - API Key

    func loadAPIKey() {
        apiKey = try? keychain.read(key: AppConstants.apiKeyIdentifier)
        if let apiKey {
            apiService = DeepSeekAPIService(apiKey: apiKey)
            isAPIKeyValid = true
        }
    }

    func saveAPIKey(_ key: String) async -> Bool {
        do {
            let service = DeepSeekAPIService(apiKey: key)
            let valid = try await service.validateAPIKey()
            if valid {
                try keychain.save(key: AppConstants.apiKeyIdentifier, value: key)
                self.apiKey = key
                self.apiService = service
                self.isAPIKeyValid = true
                self.errorMessage = nil
                await refresh()
                return true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }

    func clearAPIKey() {
        try? keychain.delete(key: AppConstants.apiKeyIdentifier)
        apiKey = nil
        apiService = nil
        isAPIKeyValid = false
        balance = nil
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
            let info = try await apiService.fetchBalance()
            balance = info
            lastUpdated = Date()
            writeSnapshot()
        } catch {
            errorMessage = error.localizedDescription
            if case APIError.unauthorized = error {
                isAPIKeyValid = false
            }
            // Still write snapshot with last-known data
            writeSnapshot()
        }

        isLoading = false
    }

    // MARK: - Snapshot

    private func writeSnapshot() {
        tracker.buildAndWriteSnapshot(balance: balance, monthlyBudget: monthlyBudget)
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
