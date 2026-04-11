import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var opacity = 0.0
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.15, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // App Icon
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0, green: 0.8, blue: 1),
                                Color(red: 0, green: 0.6, blue: 0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1 : 0.8)
                    .opacity(opacity)

                VStack(spacing: 12) {
                    Text("Tango")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Project Management for Teams")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .opacity(opacity)

                Spacer()

                VStack(spacing: 16) {
                    Text("Stay organized, collaborate seamlessly, and ship faster with Tango—your personal Taiga project management companion.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineLimit(4)

                    Button(action: onDismiss) {
                        Text("Let's Get Started")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0, green: 0.8, blue: 1),
                                        Color(red: 0, green: 0.6, blue: 0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .scaleEffect(isAnimating ? 1 : 0.95)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(opacity)
            }
        }
        .task {
            withAnimation(.easeInOut(duration: 0.8)) {
                opacity = 1
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashScreenView(onDismiss: {})
}
