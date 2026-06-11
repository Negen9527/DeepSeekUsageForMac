import SwiftUI

/// A 7-day mini bar chart showing usage trends.
struct TrendChartView: View {
    let dataPoints: [WidgetSnapshot.DailyPoint]

    private var maxValue: Int {
        let max = dataPoints.map(\.tokens).max() ?? 1
        return max > 0 ? max : 1
    }

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 6) {
            // Chart bars
            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(dataPoints, id: \.dateString) { point in
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(point.dateString == todayKey
                                    ? AppTheme.accentCyan
                                    : AppTheme.accentCyan.opacity(0.4)
                                )
                                .frame(
                                    width: max((geo.size.width - 36) / 7, 6),
                                    height: max(CGFloat(point.tokens) / CGFloat(maxValue) * geo.size.height, 2)
                                )
                        }
                    }
                }
            }

            // Day labels
            HStack(spacing: 6) {
                ForEach(dataPoints, id: \.dateString) { point in
                    Text(point.dateString)
                        .font(.system(size: 8))
                        .foregroundColor(AppTheme.textMuted)
                        .frame(width: max(30, 10))
                }
            }
        }
    }
}

// Version for widget use (no UIScreen dependency, fixed sizing)
struct TrendChartViewCompact: View {
    let dataPoints: [WidgetSnapshot.DailyPoint]
    let chartHeight: CGFloat
    let barWidth: CGFloat
    let spacing: CGFloat

    @State private var barScales: [CGFloat]

    init(dataPoints: [WidgetSnapshot.DailyPoint], chartHeight: CGFloat, barWidth: CGFloat, spacing: CGFloat) {
        self.dataPoints = dataPoints
        self.chartHeight = chartHeight
        self.barWidth = barWidth
        self.spacing = spacing
        self._barScales = State(initialValue: Array(repeating: CGFloat(0), count: dataPoints.count))
    }

    private var maxValue: Int {
        let max = dataPoints.map(\.tokens).max() ?? 1
        return max > 0 ? max : 1
    }

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(dataPoints.indices, id: \.self) { index in
                    let point = dataPoints[index]
                    let targetHeight = max(CGFloat(point.tokens) / CGFloat(maxValue) * chartHeight, 2)

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(point.dateString == todayKey
                                ? AppTheme.accentCyan
                                : AppTheme.accentCyan.opacity(0.35)
                            )
                            .frame(width: barWidth, height: barScales[index] * targetHeight)
                    }
                }
            }
            .frame(height: chartHeight)

            HStack(spacing: spacing) {
                ForEach(dataPoints, id: \.dateString) { point in
                    Text(point.dateString)
                        .font(.system(size: 8))
                        .foregroundColor(AppTheme.textMuted)
                        .frame(width: barWidth)
                }
            }
        }
        .onAppear {
            animateBars()
        }
        .onChange(of: dataPoints.map(\.tokens)) { _, _ in
            barScales = Array(repeating: CGFloat(0), count: dataPoints.count)
            animateBars()
        }
    }

    private func animateBars() {
        for index in dataPoints.indices {
            withAnimation(.easeOut(duration: 0.5).delay(Double(index) * 0.06)) {
                barScales[index] = 1
            }
        }
    }
}

#if DEBUG
struct TrendChartView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.background
            TrendChartViewCompact(
                dataPoints: WidgetSnapshot.placeholder.trend,
                chartHeight: 60,
                barWidth: 22,
                spacing: 6
            )
            .padding()
            .frame(width: 280)
        }
    }
}
#endif
