import SwiftUI

@main
struct DeepSeekUsageApp: App {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showDashboard: Bool = false

    var body: some Scene {
        // Primary window: shows LoginView first, then Dashboard after auth
        WindowGroup {
            Group {
                if showDashboard && viewModel.isAPIKeyValid {
                    DesktopWidgetView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    LoginView(viewModel: viewModel)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showDashboard)
            .animation(.easeInOut(duration: 0.4), value: viewModel.isAPIKeyValid)
            .onAppear {
                if viewModel.isAPIKeyValid {
                    showDashboard = true
                    configureFloatingWindow()
                }
            }
            .onChange(of: viewModel.isAPIKeyValid) { _, valid in
                if valid {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showDashboard = true
                    }
                    configureFloatingWindow()
                } else {
                    showDashboard = false
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // Menu bar extra for quick access
        MenuBarExtra("DeepSeek", systemImage: AppTheme.iconTrend) {
            MenuBarContentView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Window("设置", id: "settings") {
            SettingsView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }

    private func configureFloatingWindow() {
        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.level = .floating
            }
        }
    }
}
