import SwiftUI

public struct AppSettingsView: View {
    private enum SupportTopic: String, CaseIterable, Identifiable {
        case errors = "Errors"
        case featureRequest = "Feature Request"
        case securityPrivacyInquiry = "Security or Privacy Inquiry"

        var id: String { rawValue }
    }

    private enum AppearanceMode: String, CaseIterable, Identifiable {
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

    private enum AccentColorOption: String, CaseIterable, Identifiable {
        case system
        case blue
        case green
        case orange
        case red

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system:
                return "System"
            case .blue:
                return "Blue"
            case .green:
                return "Green"
            case .orange:
                return "Orange"
            case .red:
                return "Red"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage("app-appearance-mode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @AppStorage("app-accent-color") private var accentColorRaw: String = AccentColorOption.system.rawValue
    @AppStorage("taiga-base-url") private var taigaBaseURL: String = "https://api.taiga.io/api/v1"

    @State private var supportTopic: SupportTopic = .errors
    @State private var supportDetails = ""
    @State private var includesLogs = true
    @State private var supportErrorMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color scheme", selection: $appearanceModeRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }
                .listRowBackground(.ultraThinMaterial)

                Section("Accent Color") {
                    Picker("Tint", selection: $accentColorRaw) {
                        ForEach(AccentColorOption.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.inline)
                }
                .listRowBackground(.ultraThinMaterial)

                Section("Support") {
                    Picker("Topic", selection: $supportTopic) {
                        ForEach(SupportTopic.allCases) { topic in
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
                .listRowBackground(.ultraThinMaterial)
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
            bodyLines.append(contentsOf: supportLogLines())
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

    private func supportLogLines() -> [String] {
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

#Preview {
    AppSettingsView()
}