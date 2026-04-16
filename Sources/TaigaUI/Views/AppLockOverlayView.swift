import SwiftUI
import TaigaCore
import LocalAuthentication

public struct AppLockOverlayView: View {
    @State private var passcode = ""
    @State private var errorMessage: String?
    @State private var attemptCount = 0
    @State private var shakeTrigger = false
    @State private var showBiometric = false
    @State private var biometricImageName = "faceid"
    private let securityService: SecurityLockService
    private let onUnlock: () -> Void
    private let onLogout: () -> Void

    public init(
        securityService: SecurityLockService,
        onUnlock: @escaping () -> Void,
        onLogout: @escaping () -> Void
    ) {
        self.securityService = securityService
        self.onUnlock = onUnlock
        self.onLogout = onLogout
    }

    public var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                PasscodeEntryView(
                    title: "Enter Passcode",
                    showBiometricButton: showBiometric,
                    biometricImage: biometricImageName,
                    onSubmit: { submitted in
                        submitPasscode(submitted)
                    },
                    onBiometric: biometricTapped
                )
                .modifier(ShakeEffect(animating: shakeTrigger))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.bottom, 16)
                        .transition(.opacity)
                }

                Button("Logout") {
                    onLogout()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 24)
            }
        }
        .task {
            await configureBiometric()
            await attemptBiometric()
        }
    }

    private func configureBiometric() async {
        let biometricType = await securityService.biometricType()
        let biometricEnabled = await securityService.isBiometricEnabled()
        let canUseBiometrics = await securityService.canUseBiometrics()
        let image = imageName(for: biometricType)
        await MainActor.run {
            showBiometric = biometricEnabled && canUseBiometrics
            biometricImageName = image
        }
    }

    private func validatePasscode(_ passcode: String) async {
        let isValid = await securityService.validatePasscode(passcode)
        await MainActor.run {
            if isValid {
                errorMessage = nil
                attemptCount = 0
                onUnlock()
            } else {
                attemptCount += 1
                errorMessage = "Incorrect passcode. Attempt \(attemptCount)/5"
                withAnimation(.default) {
                    shakeTrigger.toggle()
                }
                if attemptCount >= 5 {
                    onLogout()
                }
            }
        }
    }

    private func attemptBiometric() async {
        let enabled = await securityService.isBiometricEnabled()
        let canUse = await securityService.canUseBiometrics()
        guard enabled && canUse else { return }

        let success = await securityService.authenticateWithBiometrics(reason: "Unlock Taiga")
        await MainActor.run {
            if success {
                errorMessage = nil
                attemptCount = 0
                onUnlock()
            }
        }
    }

    private func submitPasscode(_ passcode: String) {
        Swift.Task { await validatePasscode(passcode) }
    }

    private func biometricTapped() {
        Swift.Task { await attemptBiometric() }
    }

    private func imageName(for type: LABiometryType) -> String {
        switch type {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "eye"
        default:
            return "lock.open.fill"
        }
    }
}

private struct ShakeEffect: GeometryEffect {
    var animating: Bool

    var animatableData: CGFloat {
        get { animating ? 1 : 0 }
        set { _ = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset: CGFloat = animating ? 8 : 0
        return ProjectionTransform(CGAffineTransform(translationX: offset * sin(animatableData * .pi * 4), y: 0))
    }
}
