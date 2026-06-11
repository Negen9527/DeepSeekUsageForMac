import SwiftUI

/// Centered login card for API Key entry. Shown before the dashboard when no valid key exists.
struct LoginView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var apiKeyInput: String = ""
    @State private var isValidating: Bool = false
    @State private var localError: String?
    @State private var cardOpacity: Double = 0
    @State private var cardOffset: CGFloat = 30
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Card
                VStack(spacing: 24) {
                    // Branding
                    brandingHeader

                    // API Key Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)

                        SecureField("输入你的 DeepSeek API Key", text: $apiKeyInput)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppTheme.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isFieldFocused ? AppTheme.accentCyan : AppTheme.surfaceLight, lineWidth: 1)
                                    )
                            )
                            .focused($isFieldFocused)
                            .onSubmit { performLogin() }
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    // Login Button
                    Button(action: performLogin) {
                        HStack(spacing: 8) {
                            if isValidating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 18, height: 18)
                            }
                            Text("登录")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(canLogin ? AppTheme.accentCyan : AppTheme.surfaceLight)
                    )
                    .foregroundColor(canLogin ? AppTheme.background : AppTheme.textMuted)
                    .disabled(!canLogin || isValidating)

                    // Error
                    if let error = localError ?? viewModel.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: AppTheme.iconWarning)
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.accentRed)
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.accentRed)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.accentRed.opacity(0.1))
                        )
                    }
                }
                .padding(28)
                .frame(width: 360)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.surfaceElevated)
                        .shadow(color: AppTheme.accentCyan.opacity(0.08), radius: 20, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.accentCyan.opacity(0.12), lineWidth: 1)
                )
                .opacity(cardOpacity)
                .offset(y: cardOffset)

                Spacer()
            }
        }
        .onAppear {
            isFieldFocused = true
            withAnimation(.easeOut(duration: 0.5)) {
                cardOpacity = 1
                cardOffset = 0
            }
        }
    }

    // MARK: - Branding

    private var brandingHeader: some View {
        VStack(spacing: 12) {
            // Logo
            ZStack {
                Circle()
                    .stroke(AppTheme.accentCyan.opacity(0.3), lineWidth: 2)
                    .frame(width: 56, height: 56)

                Circle()
                    .fill(AppTheme.accentCyan)
                    .frame(width: 10, height: 10)
            }

            VStack(spacing: 6) {
                Text("DeepSeek")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("登录以查看用量信息")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
    }

    // MARK: - Helpers

    private var canLogin: Bool {
        !apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func performLogin() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }

        localError = nil
        isValidating = true

        Task {
            let success = await viewModel.saveAPIKey(key)
            isValidating = false
            if !success {
                localError = "API Key 验证失败，请检查后重试"
            }
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: DashboardViewModel())
    }
}
#endif
