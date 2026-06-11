import WidgetKit
import SwiftUI

/// Single timeline entry used by all widget sizes.
struct UsageEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let isPlaceholder: Bool
}

/// TimelineProvider that reads the latest WidgetSnapshot from shared App Group UserDefaults.
struct UsageTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: Date(), snapshot: .placeholder, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        let snapshot = loadSnapshot()
        completion(UsageEntry(date: Date(), snapshot: snapshot, isPlaceholder: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let snapshot = loadSnapshot()
        let entry = UsageEntry(date: Date(), snapshot: snapshot, isPlaceholder: false)
        let nextRefresh = Date().addingTimeInterval(AppConstants.refreshInterval)
        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func loadSnapshot() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID),
              let data = defaults.data(forKey: AppConstants.snapshotKey) else {
            return .placeholder
        }
        return (try? JSONDecoder().decode(WidgetSnapshot.self, from: data)) ?? .placeholder
    }
}
