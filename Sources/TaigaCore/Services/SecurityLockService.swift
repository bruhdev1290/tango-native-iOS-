import Foundation
import LocalAuthentication

/// Manages app-level passcode and biometric authentication.
public actor SecurityLockService: Sendable {
    private let keychain = KeychainStore()
    private let passcodeKey = "app-passcode"
    private let biometricEnabledKey = "biometric-enabled"

    public init() {}

    public func isPasscodeSet() -> Bool {
        keychain.data(for: passcodeKey) != nil
    }

    public func setPasscode(_ passcode: String) throws {
        guard let data = passcode.data(using: .utf8) else {
            throw TaigaError.unknown
        }
        try keychain.set(data, for: passcodeKey)
    }

    public func validatePasscode(_ passcode: String) -> Bool {
        guard let data = keychain.data(for: passcodeKey),
              let stored = String(data: data, encoding: .utf8) else {
            return false
        }
        return stored == passcode
    }

    public func removePasscode() {
        keychain.remove(passcodeKey)
        keychain.remove(biometricEnabledKey)
    }

    public func isBiometricEnabled() -> Bool {
        guard let data = keychain.data(for: biometricEnabledKey),
              let value = String(data: data, encoding: .utf8) else {
            return false
        }
        return value == "true"
    }

    public func setBiometricEnabled(_ enabled: Bool) throws {
        let data = enabled ? Data("true".utf8) : Data("false".utf8)
        try keychain.set(data, for: biometricEnabledKey)
    }

    public func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    public func biometricType() -> LABiometryType {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.biometryType
    }

    public func authenticateWithBiometrics(reason: String) async -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
