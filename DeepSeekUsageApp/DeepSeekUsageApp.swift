import SwiftUI

@main
struct DeepSeekUsageApp: App {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some Scene {
        // Main floating desktop widget window
        WindowGroup {
            DesktopWidgetView(viewModel: viewModel)
                .frame(minWidth: 380, maxWidth: 420, minHeight: 520, maxHeight: 620)
                .onAppear {
                    configureFloatingWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.topTrailing)

        // Menu bar extra for quick access
        MenuBarExtra("DeepSeek", systemImage: AppTheme.iconTrend) {
            MenuBarContentView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }

    private func configureFloatingWindow() {
        DispatchQueue.main.async {
            for window in NSApp.windows where window.level != .floating {
                window.level = .floating
                window.isMovableByWindowBackground = true
            }
        }
    }
}
