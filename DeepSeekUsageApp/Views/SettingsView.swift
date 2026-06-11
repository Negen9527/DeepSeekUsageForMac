import SwiftUI

/// Settings window for API key entry, budget configuration, and manual refresh.
struct SettingsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var apiKeyInput: String = ""
    @State private var budgetInput: String = ""
    @State private var isValidating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Circle()
                    .fill(AppTheme.accentCyan)
                    .frame(width: 12, height: 12)
                Text("DeepSeek 用量设置")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
            }

            Divider()

            // API Key section
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.headline)

                HStack(spacing: 8) {
                    SecureField("输入你的 DeepSeek API Key", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                    Button(action: validateAndSave) {
                        HStack(spacing: 4) {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: AppTheme.iconCheckmark)
                            }
                            Text("验证并保存")
                        }
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accentCyan)
                }

                if viewModel.isAPIKeyValid {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.accentGreen)
                            .font(.caption)
                        Text("API Key 已验证")
                            .font(.caption)
                            .foregroundColor(AppTheme.accentGreen)
                    }

                    Button("清除 API Key") {
                        viewModel.clearAPIKey()
                        apiKeyInput = ""
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }

                if let error = viewModel.errorMessage {
                    HStack(spacing: 4) {
                        Image(systemName: AppTheme.iconWarning)
                            .foregroundColor(AppTheme.accentRed)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(AppTheme.accentRed)
                    }
                }
            }

            Divider()

            // Budget section
            VStack(alignment: .leading, spacing: 8) {
                Text("月度预算")
                    .font(.headline)

                HStack(spacing: 8) {
                    Text("¥")
                        .foregroundColor(.secondary)
                    TextField("预算金额", text: $budgetInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)

                    Text("/ 月")
                        .foregroundColor(.secondary)

                    Button("保存") {
                        if let value = Double(budgetInput.replacingOccurrences(of: ",", with: ".")), value > 0 {
                            viewModel.setBudget(value)
                        }
                    }
                    .disabled(Double(budgetInput.replacingOccurrences(of: ",", with: ".")) == nil)
                    .buttonStyle(.bordered)
                }
                .onAppear {
                    budgetInput = String(format: "%.2f", viewModel.monthlyBudget)
                }
            }

            Divider()

            // Data section
            VStack(alignment: .leading, spacing: 8) {
                Text("数据")
                    .font(.headline)

                HStack {
                    if let lastUpdated = viewModel.lastUpdated {
                        Text("上次更新: \(lastUpdated, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("尚未获取数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: refreshData) {
                        HStack(spacing: 4) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: AppTheme.iconRefresh)
                            }
                            Text("立即刷新")
                        }
                    }
                    .disabled(!viewModel.isAPIKeyValid || viewModel.isLoading)
                    .buttonStyle(.bordered)
                }
            }

            Spacer()

            // Footer
            HStack {
                Spacer()
                Text("DeepSeek Usage Widget")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .frame(width: 480, height: 420)
        .onAppear {
            if let key = try? KeychainService().read(key: AppConstants.apiKeyIdentifier) {
                apiKeyInput = key
            }
        }
    }

    private func validateAndSave() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        isValidating = true
        Task {
            let success = await viewModel.saveAPIKey(key)
            isValidating = false
            if !success, !viewModel.isAPIKeyValid {
                apiKeyInput = ""
            }
        }
    }

    private func refreshData() {
        Task {
            await viewModel.refresh()
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: DashboardViewModel())
    }
}
#endif
