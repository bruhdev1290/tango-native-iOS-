import SwiftUI

public struct PasscodeEntryView: View {
    public let title: String
    public let subtitle: String?
    public let showBiometricButton: Bool
    public let biometricImage: String?
    public let onSubmit: (String) -> Void
    public let onBiometric: () -> Void

    @State private var passcode = ""
    @State private var shakeTrigger = false
    private let maxDigits = 4

    public init(
        title: String,
        subtitle: String? = nil,
        showBiometricButton: Bool = false,
        biometricImage: String? = nil,
        onSubmit: @escaping (String) -> Void,
        onBiometric: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBiometricButton = showBiometricButton
        self.biometricImage = biometricImage
        self.onSubmit = onSubmit
        self.onBiometric = onBiometric
    }

    public var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.semibold))

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.top, 40)

            HStack(spacing: 16) {
                ForEach(0..<maxDigits, id: \.self) { index in
                    Circle()
                        .fill(index < passcode.count ? Color.primary : Color.primary.opacity(0.2))
                        .frame(width: 14, height: 14)
                }
            }
            .modifier(ShakeEffect(animating: shakeTrigger))

            Spacer()

            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 24) {
                        ForEach(1..<4) { col in
                            let digit = row * 3 + col
                            NumberButton(digit: digit) {
                                appendDigit(digit)
                            }
                        }
                    }
                }

                HStack(spacing: 24) {
                    if showBiometricButton, let biometricImage {
                        NumberButton(systemImage: biometricImage, action: onBiometric)
                    } else {
                        Color.clear
                            .frame(width: 72, height: 72)
                    }

                    NumberButton(digit: 0, action: { appendDigit(0) })

                    NumberButton(systemImage: "delete.backward.fill") {
                        removeLastDigit()
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 32)
    }

    private func appendDigit(_ digit: Int) {
        guard passcode.count < maxDigits else { return }
        passcode.append(String(digit))
        if passcode.count == maxDigits {
            onSubmit(passcode)
        }
    }

    private func removeLastDigit() {
        guard !passcode.isEmpty else { return }
        passcode.removeLast()
    }

    public func shake() {
        withAnimation(.default) {
            shakeTrigger.toggle()
        }
    }

    public func clear() {
        passcode = ""
    }
}

private struct NumberButton: View {
    let digit: Int?
    let systemImage: String?
    let action: () -> Void

    init(digit: Int, action: @escaping () -> Void) {
        self.digit = digit
        self.systemImage = nil
        self.action = action
    }

    init(systemImage: String, action: @escaping () -> Void) {
        self.digit = nil
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 72, height: 72)

                if let digit {
                    Text("\(digit)")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.primary)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }
        }
        .buttonStyle(PasscodeButtonStyle())
    }
}

private struct PasscodeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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

#Preview {
    PasscodeEntryView(
        title: "Enter Passcode",
        subtitle: "Unlock Taiga",
        showBiometricButton: true,
        biometricImage: "faceid",
        onSubmit: { _ in },
        onBiometric: {}
    )
}
