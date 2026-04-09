import SwiftUI
import TaigaCore

public struct LoginView: View {
    @Bindable private var viewModel: AuthViewModel
    @State private var username: String = ""
    @State private var password: String = ""
    private let onReset: () -> Void

    public init(viewModel: AuthViewModel, onReset: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onReset = onReset
    }

    public var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Taiga Sign In")
                    .font(.largeTitle.weight(.semibold))
                Text("Enter your Taiga credentials")
                    .foregroundStyle(.secondary)
            }
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

            if case .failed(let message) = viewModel.state {
                Text(message)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            Button("Clear saved session") {
                onReset()
            }
            .buttonStyle(.borderless)
            .font(.footnote)
        }
        .padding(24)
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel(authService: AuthService()))
}
