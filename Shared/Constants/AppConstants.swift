import Foundation

enum AppConstants {
    static let appGroupID = "group.com.deepseekusage.widget"
    static let snapshotKey = "widgetSnapshot"
    static let historyFileName = "usage_history.json"
    static let monthlyBudgetKey = "monthlyBudget"
    static let tokenKeychainKey = "com.deepseekusage.token"
    static let refreshInterval: TimeInterval = 900

    static let appGroupContainer: URL = {
        let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupID
        )
        guard let url else {
            fatalError("App Group container not found. Ensure App Groups capability is configured.")
        }
        return url
    }()

    static let historyFileURL: URL = {
        appGroupContainer.appendingPathComponent(historyFileName)
    }()
}
