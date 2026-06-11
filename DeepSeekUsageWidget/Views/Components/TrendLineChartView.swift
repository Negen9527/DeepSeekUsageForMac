import SwiftUI

/// Animated 7-day line chart with gradient fill and dot markers.
/// Line draws progressively from left to right on appear.
struct TrendLineChartView: View {
    let dataPoints: [WidgetSnapshot.DailyPoint]
    let chartHeight: CGFloat

    @State private var lineProgress: CGFloat = 0

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
            GeometryReader { geo in
                let width = geo.size.width
                let stepX = dataPoints.count > 1 ? width / CGFloat(dataPoints.count - 1) : 0
                let points = dataPoints.enumerated().map { i, pt -> CGPoint in
                    CGPoint(
                        x: CGFloat(i) * stepX,
                        y: chartHeight - (CGFloat(pt.tokens) / CGFloat(maxValue) * chartHeight)
                    )
                }

                ZStack {
                    // Gradient fill under the line
                    linePath(points: points, width: width)
                        .trim(from: 0, to: lineProgress)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.accentCyan.opacity(0.3), AppTheme.accentCyan.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            style: StrokeStyle(lineWidth: chartHeight, lineCap: .butt)
                        )
                        .clipShape(Rectangle())

                    // The line itself
                    linePath(points: points, width: width)
                        .trim(from: 0, to: lineProgress)
                        .stroke(
                            AppTheme.accentCyan,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )

                    // Dot markers
                    ForEach(dataPoints.indices, id: \.self) { index in
                        let point = points[index]
                        Circle()
                            .fill(dataPoints[index].dateString == todayKey
                                ? AppTheme.accentCyan
                                : AppTheme.accentCyan.opacity(0.5))
                            .frame(width: dataPoints[index].dateString == todayKey ? 6 : 4,
                                   height: dataPoints[index].dateString == todayKey ? 6 : 4)
                            .position(x: point.x, y: point.y)
                            .opacity(lineProgress >= CGFloat(index) / CGFloat(dataPoints.count - 1) ? 1 : 0)
                    }
                }
            }
            .frame(height: chartHeight)

            // Day labels
            HStack {
                ForEach(dataPoints, id: \.dateString) { point in
                    Text(point.dateString)
                        .font(.system(size: 8))
                        .foregroundColor(point.dateString == todayKey
                            ? AppTheme.accentCyan
                            : AppTheme.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                lineProgress = 1
            }
        }
        .onChange(of: dataPoints.map(\.tokens)) { _, _ in
            lineProgress = 0
            withAnimation(.easeOut(duration: 1.2)) {
                lineProgress = 1
            }
        }
    }

    private func linePath(points: [CGPoint], width: CGFloat) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)

            for i in 1..<points.count {
                let current = points[i]
                let previous = points[i - 1]
                let midX = (previous.x + current.x) / 2
                path.addCurve(to: current, control1: CGPoint(x: midX, y: previous.y),
                              control2: CGPoint(x: midX, y: current.y))
            }
        }
    }
}

#if DEBUG
struct TrendLineChartView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.background
            TrendLineChartView(
                dataPoints: WidgetSnapshot.placeholder.trend,
                chartHeight: 60
            )
            .padding()
            .frame(width: 300)
        }
    }
}
#endif
