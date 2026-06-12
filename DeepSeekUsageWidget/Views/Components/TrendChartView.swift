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

// MARK: - Compact version with hover tooltip (overlay style)

struct TrendChartViewCompact: View {
    let dataPoints: [WidgetSnapshot.DailyPoint]
    let chartHeight: CGFloat
    let barWidth: CGFloat
    let spacing: CGFloat

    @State private var barScales: [CGFloat]
    @State private var hoveredIndex: Int?

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

    private let tooltipReservedHeight: CGFloat = 24

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: spacing) {
                ForEach(dataPoints.indices, id: \.self) { index in
                    let point = dataPoints[index]
                    let targetHeight = max(CGFloat(point.tokens) / CGFloat(maxValue) * chartHeight, 2)
                    let isHovered = hoveredIndex == index

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(point.dateString == todayKey
                                ? AppTheme.accentCyan
                                : AppTheme.accentCyan.opacity(0.35)
                            )
                            .frame(width: barWidth, height: barScales[index] * targetHeight)
                            .brightness(isHovered ? 0.25 : 0)
                            .scaleEffect(isHovered ? 1.08 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                    }
                    .frame(height: chartHeight)
                }
            }
            .frame(height: chartHeight)
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let estimatedIndex = Int((location.x / (barWidth + spacing)).rounded())
                    let clamped = min(max(estimatedIndex, 0), dataPoints.count - 1)
                    if hoveredIndex != clamped {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            hoveredIndex = clamped
                        }
                    }
                case .ended:
                    withAnimation(.easeInOut(duration: 0.1)) {
                        hoveredIndex = nil
                    }
                }
            }
            .overlay(alignment: .top) {
                // Reserved tooltip space — always occupies fixed height to prevent layout deformation
                VStack {
                    if let index = hoveredIndex, index < dataPoints.count {
                        let pt = dataPoints[index]
                        let chartWidth = CGFloat(dataPoints.count) * barWidth + CGFloat(dataPoints.count - 1) * spacing
                        let offsetX = (CGFloat(index) - CGFloat(dataPoints.count - 1) / 2) * (barWidth + spacing)
                        let tipHalf: CGFloat = 85
                        let maxOffset = (chartWidth / 2) - tipHalf
                        let clampedX = min(max(offsetX, -maxOffset), maxOffset)
                        HStack(spacing: 4) {
                            Text(pt.dateString).font(.system(size: 9, weight: .semibold)).foregroundColor(AppTheme.accentCyan)
                            Text("·").font(.system(size: 8)).foregroundColor(AppTheme.textMuted)
                            Text(formatNumber(pt.tokens)).font(.system(size: 9, weight: .medium)).foregroundColor(AppTheme.textPrimary)
                            Text("·").font(.system(size: 8)).foregroundColor(AppTheme.textMuted)
                            Text("¥\(String(format: "%.2f", pt.cost))").font(.system(size: 9)).foregroundColor(AppTheme.accentGreen)
                            Text("·").font(.system(size: 8)).foregroundColor(AppTheme.textMuted)
                            Text("\(pt.requests)次").font(.system(size: 9)).foregroundColor(AppTheme.textMuted)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 4).fill(AppTheme.surfaceElevated))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 0.5))
                        .offset(x: clampedX)
                    }
                }
                .frame(height: tooltipReservedHeight)
                .offset(y: -chartHeight - 2)
            }

            HStack(spacing: spacing) {
                ForEach(dataPoints, id: \.dateString) { point in
                    Text(point.dateString)
                        .font(.system(size: 8))
                        .foregroundColor(AppTheme.textMuted)
                        .frame(width: barWidth)
                }
            }
        }
        .onAppear { animateBars() }
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

    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return n.formatted()
    }
}

#if DEBUG
struct TrendChartViewCompact_Previews: PreviewProvider {
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
