import SwiftUI
import TaigaCore

public struct LoginView: View {
    @Bindable private var viewModel: AuthViewModel
    @State private var username: String = ""
    @State private var password: String = ""
    private let onReset: () -> Void
    private let enableGitHubAuth: Bool

    public init(
        viewModel: AuthViewModel,
        enableGitHubAuth: Bool = true,
        onReset: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.enableGitHubAuth = enableGitHubAuth
        self.onReset = onReset
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Taiga Sign In")
                    .font(.largeTitle.weight(.semibold))
                Text("Enter your Taiga credentials")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Email/Password Form
            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            // Sign In Button
            Button(action: { Swift.Task { await viewModel.login(username: username, password: password) } }) {
                HStack {
                    if case .loading = viewModel.state {
                        ProgressView()
                    }
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(username.isEmpty || password.isEmpty || (viewModel.state == .loading))

            // Divider
            if enableGitHubAuth {
                HStack {
                    Rectangle()
                        .fill(.separator)
                        .frame(height: 1)
                    Text("or")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(.separator)
                        .frame(height: 1)
                }

                // GitHub Sign In Button
                GitHubSignInButton {
                    await viewModel.loginWithGitHub()
                }
                .disabled(viewModel.state == .loading)
            }

            // Error Message
            if case .failed(let message) = viewModel.state {
                Text(message)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Clear Session Button
            Button("Clear saved session") {
                onReset()
            }
            .buttonStyle(.borderless)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}

// MARK: - GitHub Sign In Button

struct GitHubSignInButton: View {
    let action: () async -> Void
    @State private var isLoading = false

    var body: some View {
        Button(action: {
            isLoading = true
            Swift.Task {
                await action()
                isLoading = false
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                Text("Sign in with GitHub")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 36/255, green: 41/255, blue: 46/255))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel(authService: AuthService()))
}
