import SwiftUI

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

    var body: some View {
        Form {
            Section("Tint") {
                Picker("Accent color", selection: $accentColorRaw) {
                    ForEach(AppSettingsView.AccentColorOption.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(.inline)
            }
        }
        .navigationTitle("Accent Color")
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

#Preview {
    AppSettingsView()
}