import SwiftUI

/// Configuration panel shown as a sheet from the main dashboard.
/// Allows users to set their DeepSeek platform Token and monthly budget.
struct ConfigPanelView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var tokenInput: String = ""
    @State private var budgetInput: String = ""
    @State private var isValidating: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(AppTheme.accentCyan)
                    .frame(width: 10, height: 10)
                Text("配置")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Token section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Token")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)

                        HStack(spacing: 8) {
                            SecureField("输入 DeepSeek 平台 Token", text: $tokenInput)
                                .textFieldStyle(.plain)
                                .font(.system(.body, design: .monospaced))
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AppTheme.surface)
                                )
                                .foregroundColor(AppTheme.textPrimary)

                            Button(action: validateAndSave) {
                                HStack(spacing: 4) {
                                    if isValidating {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .frame(width: 14, height: 14)
                                    }
                                    Text("验证并保存")
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }
                            .disabled(tokenInput.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accentCyan)
                            .controlSize(.small)
                        }

                        if viewModel.isTokenValid {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.accentGreen)
                                    .font(.caption)
                                Text("Token 已验证")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.accentGreen)
                            }

                            Button("清除 Token") {
                                viewModel.clearToken()
                                tokenInput = ""
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }

                        if let error = viewModel.errorMessage {
                            HStack(spacing: 4) {
                                Image(systemName: AppTheme.iconWarning)
                                    .foregroundColor(AppTheme.accentRed)
                                    .font(.caption)
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
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)

                        HStack(spacing: 8) {
                            Text("¥")
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("预算金额", text: $budgetInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)

                            Text("/ 月")
                                .foregroundColor(AppTheme.textMuted)

                            Button("保存") {
                                if let value = Double(budgetInput.replacingOccurrences(of: ",", with: ".")), value > 0 {
                                    viewModel.setBudget(value)
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    Divider()

                    // Refresh
                    VStack(alignment: .leading, spacing: 8) {
                        Text("数据")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)

                        HStack {
                            if let lastUpdated = viewModel.lastUpdated {
                                Text("上次更新: \(lastUpdated, style: .time)")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textMuted)
                            } else {
                                Text("尚未获取数据")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            Spacer()
                            Button(action: {
                                Task { await viewModel.refresh() }
                            }) {
                                HStack(spacing: 4) {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .frame(width: 14, height: 14)
                                    } else {
                                        Image(systemName: AppTheme.iconRefresh)
                                    }
                                    Text("立即刷新")
                                }
                            }
                            .disabled(!viewModel.isTokenValid || viewModel.isLoading)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 420)
        .background(AppTheme.background)
        .onAppear {
            if let tok = try? KeychainService().read(key: AppConstants.tokenKeychainKey) {
                tokenInput = tok
            }
            budgetInput = String(format: "%.2f", viewModel.monthlyBudget)
        }
    }

    private func validateAndSave() {
        let tok = tokenInput.trimmingCharacters(in: .whitespaces)
        guard !tok.isEmpty else { return }
        isValidating = true
        Task {
            let success = await viewModel.saveToken(tok)
            isValidating = false
            if !success, !viewModel.isTokenValid {
                tokenInput = ""
            }
        }
    }
}
