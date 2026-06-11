import WidgetKit
import SwiftUI

/// Dispatches to the correct widget view based on the widget family.
struct DeepSeekUsageWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: UsageEntry

    var body: some View {
        if entry.isPlaceholder {
            content
                .redacted(reason: .placeholder)
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
                .containerBackground(AppTheme.background, for: .widget)
        case .systemMedium:
            MediumWidgetView(entry: entry)
                .containerBackground(AppTheme.background, for: .widget)
        case .systemLarge:
            LargeWidgetView(entry: entry)
                .containerBackground(AppTheme.background, for: .widget)
        default:
            MediumWidgetView(entry: entry)
                .containerBackground(AppTheme.background, for: .widget)
        }
    }
}

@main
struct DeepSeekUsageWidget: Widget {
    let kind: String = "com.deepseekusage.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: UsageTimelineProvider()
        ) { entry in
            DeepSeekUsageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DeepSeek 用量")
        .description("查看 DeepSeek API 的使用量和余额")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
