import SwiftUI

/// Animated line chart with gradient fill, dot markers, and hover tooltip.
struct TrendLineChartView: View {
    let dataPoints: [WidgetSnapshot.DailyPoint]
    let chartHeight: CGFloat

    @State private var lineProgress: CGFloat = 0
    @State private var hoveredIndex: Int?

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
            GeometryReader { geo in
                let width = geo.size.width
                let pxStep = dataPoints.count > 1 ? width / CGFloat(dataPoints.count - 1) : 0
                let cgPoints = dataPoints.enumerated().map { i, pt -> CGPoint in
                    CGPoint(
                        x: CGFloat(i) * pxStep,
                        y: chartHeight - (CGFloat(pt.tokens) / CGFloat(maxValue) * chartHeight)
                    )
                }

                VStack(spacing: 2) {
                    // Reserved tooltip space — always occupies fixed height to prevent layout deformation
                    ZStack(alignment: .bottom) {
                        if let index = hoveredIndex, index < dataPoints.count {
                            let pt = dataPoints[index]
                            let hoverX = cgPoints[index].x
                            // Clamp tooltip to stay within chart bounds
                            let tipHalf: CGFloat = 85
                            let idealOffset = hoverX - width / 2
                            let clampedOffset = min(max(idealOffset, -(width / 2) + tipHalf), (width / 2) - tipHalf)
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
                            .offset(x: clampedOffset)
                        }
                    }
                    .frame(height: tooltipReservedHeight)

                    ZStack {
                        // Gradient fill under the line
                        lineFill(cgPoints: cgPoints)
                            .trim(from: 0, to: lineProgress)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.accentCyan.opacity(0.3), AppTheme.accentCyan.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(Rectangle())

                        // The line itself
                        linePath(cgPoints: cgPoints)
                            .trim(from: 0, to: lineProgress)
                            .stroke(
                                AppTheme.accentCyan,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                            )

                        // Hover indicator line
                        if let hovered = hoveredIndex, hovered < cgPoints.count {
                            let pt = cgPoints[hovered]
                            Rectangle()
                                .fill(AppTheme.textMuted.opacity(0.5))
                                .frame(width: 1)
                                .frame(height: chartHeight)
                                .position(x: pt.x, y: chartHeight / 2)
                        }

                        // Dot markers
                        ForEach(dataPoints.indices, id: \.self) { index in
                            let point = cgPoints[index]
                            let isToday = dataPoints[index].dateString == todayKey
                            let isHovered = hoveredIndex == index

                            Circle()
                                .fill(isToday || isHovered ? AppTheme.accentCyan : AppTheme.accentCyan.opacity(0.5))
                                .frame(width: isHovered ? 7 : (isToday ? 5 : 3.5),
                                       height: isHovered ? 7 : (isToday ? 5 : 3.5))
                                .position(x: point.x, y: point.y)
                                .opacity(lineProgress >= CGFloat(index) / max(CGFloat(dataPoints.count - 1), 1) ? 1 : 0)
                        }
                    }
                    .frame(height: chartHeight)
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            let nearest = cgPoints.enumerated().min(by: {
                                abs($0.1.x - location.x) < abs($1.1.x - location.x)
                            })?.0
                            if hoveredIndex != nearest {
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    hoveredIndex = nearest
                                }
                            }
                        case .ended:
                            withAnimation(.easeInOut(duration: 0.1)) {
                                hoveredIndex = nil
                            }
                        }
                    }
                }
            }
            .frame(height: tooltipReservedHeight + 2 + chartHeight)

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

    private func linePath(cgPoints: [CGPoint]) -> Path {
        Path { path in
            guard let first = cgPoints.first else { return }
            path.move(to: first)
            for i in 1..<cgPoints.count {
                let current = cgPoints[i]
                let previous = cgPoints[i - 1]
                let midX = (previous.x + current.x) / 2
                path.addCurve(to: current, control1: CGPoint(x: midX, y: previous.y),
                              control2: CGPoint(x: midX, y: current.y))
            }
        }
    }

    private func lineFill(cgPoints: [CGPoint]) -> Path {
        Path { path in
            guard let first = cgPoints.first, let last = cgPoints.last else { return }
            path.move(to: CGPoint(x: first.x, y: chartHeight))
            path.addLine(to: first)
            for i in 1..<cgPoints.count {
                let current = cgPoints[i]
                let previous = cgPoints[i - 1]
                let midX = (previous.x + current.x) / 2
                path.addCurve(to: current, control1: CGPoint(x: midX, y: previous.y),
                              control2: CGPoint(x: midX, y: current.y))
            }
            path.addLine(to: CGPoint(x: last.x, y: chartHeight))
            path.closeSubpath()
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1fk", Double(n) / 1000.0) }
        return n.formatted()
    }
}
