import SwiftUI
import TaigaCore
import UserNotifications

public struct AppSettingsView: View {
    fileprivate enum SupportTopic: String, CaseIterable, Identifiable {
        case errors = "Errors"
        case featureRequest = "Feature Request"
        case securityPrivacyInquiry = "Security or Privacy Inquiry"

        var id: String { rawValue }
    }

    fileprivate enum AppearanceMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system:
                return "System"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            }
        }
    }

    fileprivate enum AccentColorOption: String, CaseIterable, Identifiable {
        case blueberry
        case strawberry
        case orange
        case banana
        case green
        case mint
        case teal
        case grape
        case pink
        case platinum
        case indigo

        var id: String { rawValue }

        var title: String {
            switch self {
            case .blueberry: return "Blueberry"
            case .strawberry: return "Strawberry"
            case .orange: return "Orange"
            case .banana: return "Banana"
            case .green: return "Green"
            case .mint: return "Mint"
            case .teal: return "Teal"
            case .grape: return "Grape"
            case .pink: return "Pink"
            case .platinum: return "Platinum"
            case .indigo: return "Indigo"
            }
        }

        var color: Color {
            switch self {
            case .blueberry: return Color(red: 0.0, green: 0.48, blue: 1.0)
            case .strawberry: return Color(red: 1.0, green: 0.27, blue: 0.23)
            case .orange: return Color(red: 1.0, green: 0.58, blue: 0.0)
            case .banana: return Color(red: 1.0, green: 0.8, blue: 0.0)
            case .green: return Color(red: 0.2, green: 0.78, blue: 0.35)
            case .mint: return Color(red: 0.0, green: 0.78, blue: 0.75)
            case .teal: return Color(red: 0.35, green: 0.78, blue: 0.85)
            case .grape: return Color(red: 0.6, green: 0.4, blue: 0.9)
            case .pink: return Color(red: 1.0, green: 0.3, blue: 0.5)
            case .platinum: return Color(red: 0.55, green: 0.55, blue: 0.58)
            case .indigo: return Color(red: 0.35, green: 0.35, blue: 0.85)
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @AppStorage("app-appearance-mode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("app-accent-color") private var accentColorRaw: String = AccentColorOption.blueberry.rawValue
    @AppStorage("taiga-base-url") private var taigaBaseURL: String = "https://api.taiga.io/api/v1"

    @State private var supportTopic: SupportTopic = .errors
    @State private var supportDetails = ""
    @State private var includesLogs = true
    @State private var supportErrorMessage: String?
    private let onLogout: () -> Void

    public init(onLogout: @escaping () -> Void = {}) {
        self.onLogout = onLogout
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    NavigationLink {
                        AppearanceSettingsView(appearanceModeRaw: $appearanceModeRaw)
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }

                    NavigationLink {
                        AccentColorSettingsView(accentColorRaw: $accentColorRaw)
                    } label: {
                        Label("Accent Color", systemImage: "paintpalette")
                    }

                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                Section("Help") {
                    NavigationLink {
                        SupportSettingsView(
                            supportTopic: $supportTopic,
                            supportDetails: $supportDetails,
                            includesLogs: $includesLogs,
                            supportErrorMessage: $supportErrorMessage,
                            appearanceModeRaw: appearanceModeRaw,
                            accentColorRaw: accentColorRaw,
                            taigaBaseURL: taigaBaseURL
                        )
                    } label: {
                        Label("Support", systemImage: "envelope")
                    }

                    NavigationLink {
                        GitHubSettingsView()
                    } label: {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }

                Section("Account") {
                    Button(role: .destructive) {
                        dismiss()
                        onLogout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.15), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    fileprivate static func supportLogLines(appearanceModeRaw: String, accentColorRaw: String, taigaBaseURL: String) -> [String] {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString

        return [
            "App Logs:",
            "- App version: \(appVersion) (\(buildNumber))",
            "- OS: \(osVersion)",
            "- Appearance: \(appearanceModeRaw)",
            "- Accent color: \(accentColorRaw)",
            "- Taiga API URL: \(taigaBaseURL)",
            "- Timestamp: \(Date().formatted(date: .abbreviated, time: .standard))"
        ]
    }
}

private struct GitHubSettingsView: View {
    var body: some View {
        Form {
            Section("Repository") {
                Link(
                    destination: URL(string: "https://github.com/bruhdev1290/tango-native-iOS-")!
                ) {
                    Label("View Source Code", systemImage: "link")
                }
            }
        }
        .navigationTitle("GitHub")
    }
}

private struct AppearanceSettingsView: View {
    @Binding var appearanceModeRaw: String

    var body: some View {
        Form {
            Section("Color Scheme") {
                Picker("Color scheme", selection: $appearanceModeRaw) {
                    ForEach(AppSettingsView.AppearanceMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("Appearance")
    }
}

private struct AccentColorSettingsView: View {
    @Binding var accentColorRaw: String

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Accent Color")
                    .font(.headline)
                    .padding(.horizontal, 16)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(AppSettingsView.AccentColorOption.allCases) { option in
                        ColorOptionButton(
                            option: option,
                            isSelected: accentColorRaw == option.rawValue
                        ) {
                            accentColorRaw = option.rawValue
                        }
                    }
                }
                .padding(.horizontal, 16)

                // Preview Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.headline)
                        .padding(.horizontal, 16)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Sample Text")
                                .font(.title3.weight(.semibold))
                            Spacer()
                            Text("Button")
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }

                        Text("This is how your interface will look with the selected accent color.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }

    private var selectedColor: Color {
        AppSettingsView.AccentColorOption.allCases
            .first { $0.rawValue == accentColorRaw }?.color ?? .blue
    }
}

private struct ColorOptionButton: View {
    let option: AppSettingsView.AccentColorOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(option.color)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 4 : 0)
                            .padding(isSelected ? 2 : 0)
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? option.color.opacity(0.5) : Color.clear, lineWidth: isSelected ? 2 : 0)
                    )

                Text(option.title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SupportSettingsView: View {
    @Environment(\.openURL) private var openURL

    @Binding var supportTopic: AppSettingsView.SupportTopic
    @Binding var supportDetails: String
    @Binding var includesLogs: Bool
    @Binding var supportErrorMessage: String?
    let appearanceModeRaw: String
    let accentColorRaw: String
    let taigaBaseURL: String

    var body: some View {
        Form {
            Section("Support Request") {
                Picker("Topic", selection: $supportTopic) {
                    ForEach(AppSettingsView.SupportTopic.allCases) { topic in
                        Text(topic.rawValue).tag(topic)
                    }
                }
                .pickerStyle(.menu)

                TextField("What happened?", text: $supportDetails, axis: .vertical)
                    .lineLimit(3...6)

                Toggle("Include app logs", isOn: $includesLogs)

                Button("Compose Support Email") {
                    composeSupportEmail()
                }

                if let supportErrorMessage {
                    Text(supportErrorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Support")
    }

    private func composeSupportEmail() {
        let recipient = "correspondencesandrew@gmail.com"
        let subject = "Taiga iOS Support - \(supportTopic.rawValue)"

        var bodyLines: [String] = [
            "Topic: \(supportTopic.rawValue)",
            "",
            "Details:",
            supportDetails.isEmpty ? "(No details provided)" : supportDetails,
            ""
        ]

        if includesLogs {
            bodyLines.append(
                contentsOf: AppSettingsView.supportLogLines(
                    appearanceModeRaw: appearanceModeRaw,
                    accentColorRaw: accentColorRaw,
                    taigaBaseURL: taigaBaseURL
                )
            )
        }

        let body = bodyLines.joined(separator: "\n")

        guard
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "mailto:\(recipient)?subject=\(encodedSubject)&body=\(encodedBody)")
        else {
            supportErrorMessage = "Could not prepare support email."
            return
        }

        openURL(url) { accepted in
            if accepted {
                supportErrorMessage = nil
            } else {
                supportErrorMessage = "No default email app is available."
            }
        }
    }
}

private struct NotificationSettingsView: View {
    @AppStorage("notify-assigned-items") private var notifyAssignedItems: Bool = true
    @AppStorage("notify-new-items") private var notifyNewItems: Bool = true
    @AppStorage("notify-sound") private var notifySound: Bool = true
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isCheckingAuth = true

    var body: some View {
        Form {
            Section("Notification Preferences") {
                Toggle("New Assigned Items", isOn: $notifyAssignedItems)
                    .onChange(of: notifyAssignedItems) {
                        if notifyAssignedItems {
                            requestNotificationAuth()
                        }
                    }

                Toggle("New Items in Projects", isOn: $notifyNewItems)
                    .onChange(of: notifyNewItems) {
                        if notifyNewItems {
                            requestNotificationAuth()
                        }
                    }

                Toggle("Sound", isOn: $notifySound)
            }

            Section("System") {
                if authorizationStatus == .authorized {
                    Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if authorizationStatus == .denied {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notifications Disabled", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        
                        Button(action: openSettings) {
                            Label("Open Settings", systemImage: "gear")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Checking permission...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("About") {
                Text("Receive notifications when items are assigned to you or added to projects you're a member of.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Notifications")
        .task {
            await checkAuthorizationStatus()
        }
    }

    private func requestNotificationAuth() {
        Swift.Task {
            let authorized = await NotificationManager.shared.requestAuthorization()
            await MainActor.run {
                authorizationStatus = authorized ? .authorized : .denied
            }
        }
    }

    private func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
            isCheckingAuth = false
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    AppSettingsView()
}