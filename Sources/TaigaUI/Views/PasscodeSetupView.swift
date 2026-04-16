import SwiftUI
import TaigaCore

public struct PasscodeSetupView: View {
    public enum Mode {
        case create
        case change
    }

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .enter
    @State private var firstPasscode = ""
    @State private var errorMessage: String?
    @State private var passcodeEntry: PasscodeEntryView?
    private let mode: Mode
    private let securityService: SecurityLockService
    private let onComplete: () -> Void

    private enum Step {
        case enter
        case confirm
    }

    public init(
        mode: Mode = .create,
        securityService: SecurityLockService,
        onComplete: @escaping () -> Void = {}
    ) {
        self.mode = mode
        self.securityService = securityService
        self.onComplete = onComplete
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if let passcodeEntry {
                    VStack(spacing: 0) {
                        passcodeEntry
                            .id(step)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(.bottom, 16)
                                .transition(.opacity)
                        }

                        Spacer()
                    }
                }
            }
            .navigationTitle(mode == .create ? "Set Passcode" : "Change Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                updateEntryView()
            }
        }
    }

    private func updateEntryView() {
        let title: String
        let subtitle: String
        switch step {
        case .enter:
            title = mode == .create ? "Create Passcode" : "Enter New Passcode"
            subtitle = "Choose a 4-digit passcode"
        case .confirm:
            title = "Re-enter Passcode"
            subtitle = "Confirm your 4-digit passcode"
        }

        passcodeEntry = PasscodeEntryView(
            title: title,
            subtitle: subtitle,
            onSubmit: { passcode in
                Swift.Task { await handlePasscode(passcode) }
            }
        )
    }

    private func handlePasscode(_ passcode: String) async {
        switch step {
        case .enter:
            await MainActor.run {
                firstPasscode = passcode
                step = .confirm
                errorMessage = nil
                passcodeEntry?.clear()
                updateEntryView()
            }
        case .confirm:
            if passcode == firstPasscode {
                do {
                    try await securityService.setPasscode(passcode)
                    await MainActor.run {
                        errorMessage = nil
                        onComplete()
                        dismiss()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to save passcode."
                        passcodeEntry?.shake()
                        passcodeEntry?.clear()
                    }
                }
            } else {
                await MainActor.run {
                    errorMessage = "Passcodes do not match. Try again."
                    step = .enter
                    firstPasscode = ""
                    passcodeEntry?.shake()
                    updateEntryView()
                }
            }
        }
    }
}
