# Taiga iOS Client - Agent Guide

This guide provides essential information for AI coding agents working on the Taiga iOS Client project.

## Project Overview

Taiga iOS Client is a native SwiftUI mobile application for interacting with the Taiga project management platform. It provides a clean, modern interface for viewing projects, managing backlogs, user stories, tasks, and sprints.

**Key Facts:**
- **Language**: Swift 5.9+
- **Platform**: iOS 17.0+
- **UI Framework**: SwiftUI with Observation framework (`@Observable`)
- **Architecture**: Modular Swift Package with 3 targets
- **Concurrency**: Swift async/await throughout
- **External Dependencies**: None (pure Swift/SwiftUI)

## Project Structure

The project uses Swift Package Manager with a multi-target structure:

```
TaigaClient/
├── Package.swift           # SPM package manifest
├── project.yml             # XcodeGen configuration for iOS app
├── README.md               # Human-readable documentation
├── Sources/
│   ├── TaigaCore/          # Core business logic and networking
│   │   ├── Networking/
│   │   │   └── APIClient.swift
│   │   ├── Services/
│   │   │   ├── AuthService.swift
│   │   │   ├── ItemsService.swift
│   │   │   ├── ProjectsService.swift
│   │   │   └── KeychainStore.swift
│   │   ├── Models/
│   │   │   ├── AuthToken.swift
│   │   │   ├── CurrentUser.swift
│   │   │   ├── Issue.swift
│   │   │   ├── Membership.swift
│   │   │   ├── ProjectSummary.swift
│   │   │   ├── Sprint.swift
│   │   │   ├── Task.swift
│   │   │   └── UserStory.swift
│   │   ├── GitHubOAuthConfig.swift
│   │   └── TaigaError.swift
│   ├── TaigaUI/            # SwiftUI view models and views
│   │   ├── ViewModels/
│   │   │   ├── AuthViewModel.swift
│   │   │   ├── ItemsViewModel.swift
│   │   │   └── ProjectsViewModel.swift
│   │   └── Views/
│   │       ├── AppSettingsView.swift
│   │       ├── LoginView.swift
│   │       ├── ProjectDetailView.swift
│   │       └── ProjectsListView.swift
│   └── TaigaApp/           # App entry point
│       ├── TaigaMobileApp.swift
│       ├── ContentView.swift
│       └── Info.plist
└── Tests/
    └── TaigaCoreTests/
        └── TaigaCoreTests.swift
```

## Module Responsibilities

### TaigaCore
Core library containing business logic, networking, and data models.

**Key Types:**
- `TaigaAPIClient`: Main REST API client for Taiga endpoints
- `AuthService`: Actor handling authentication, token refresh, and Keychain persistence
- `ProjectsService`: Actor for fetching projects and related user data
- `ItemsService`: Actor for backlog items (stories, tasks, sprints)
- `KeychainStore`: Simple Keychain wrapper for secure token storage
- Models: `AuthToken`, `ProjectSummary`, `UserStory`, `Task`, `Sprint`, `Issue`, `CurrentUser`, `Membership`

### TaigaUI
SwiftUI views and view models using the new Observation framework.

**Key Types:**
- `AuthViewModel`: `@Observable` class managing login state, supports username/password and GitHub OAuth
- `ProjectsViewModel`: `@Observable` class for project list and "My Work" aggregation
- `ItemsViewModel`: `@Observable` class for backlog items in a project
- `LoginView`: SwiftUI login form with instance URL input
- `ProjectsListView`: Project list with "My Work" section
- `ProjectDetailView`: Backlog view with sprints, stories, tasks; supports search and filtering
- `AppSettingsView`: Settings sheet for appearance, accent color, and support

### TaigaApp
Executable target providing the app entry point.

**Key Types:**
- `TaigaMobileApp`: `@main` app struct, configures appearance and services
- `ContentView`: Root view switching between Login and Projects based on auth state

## Build and Test Commands

### Swift Package Manager
```bash
# Build all targets
cd TaigaClient && swift build

# Run tests
swift test

# Build for iOS (requires Xcode)
swift build -Xswiftc -sdk -Xswiftc $(xcrun --sdk iphonesimulator --show-sdk-path) -Xswiftc -target -Xswiftc arm64-apple-ios17.0-simulator
```

### Xcode
```bash
# Generate Xcode project from project.yml (requires XcodeGen)
xcodegen generate

# Open in Xcode
open Tranga.xcodeproj
```

### Running the App
1. Open `Package.swift` in Xcode (File > Open...)
2. Select the `TaigaMobileApp` scheme
3. Choose an iOS 17+ simulator
4. Run

## Code Style Guidelines

### General
- Use `Sendable` conformance for all model types
- Prefer value types (structs) for models, reference types (classes/actors) for services
- Use Swift's `Codable` with explicit `CodingKeys` for API JSON mapping
- All models use snake_case CodingKeys to match Taiga API

### Concurrency
- Services are implemented as `actor` types for thread safety
- ViewModels use `@Observable` (Observation framework) with `@MainActor` annotations
- Use `async let` for parallel API calls
- Wrap completion handlers in `withCheckedThrowingContinuation` when needed

### Error Handling
- Use custom `TaigaError` enum for domain-specific errors
- All errors conform to `LocalizedError` for user-friendly messages
- Services propagate underlying errors wrapped in `TaigaError.network`

### SwiftUI Patterns
- Use `@Bindable` for observable view models in Views
- Prefer `@AppStorage` for simple user preferences
- Use `.task { }` modifiers for async view lifecycle operations
- Preview all views with mock data

## Testing Strategy

- **Unit Tests**: Located in `Tests/TaigaCoreTests/`
- **Framework**: XCTest
- **Coverage**: Focus on model decoding, service logic
- **Mocking**: Create mock services by implementing protocol-based designs or injecting `URLSession` with custom configurations

Example test pattern:
```swift
func testAuthTokenDecoding() throws {
    let json = """
    {"auth_token":"abc123","token_type":"Bearer"}
    """.data(using: .utf8)!
    let token = try JSONDecoder().decode(AuthToken.self, from: json)
    XCTAssertEqual(token.authToken, "abc123")
}
```

## Security Considerations

### Authentication
- Auth tokens stored in iOS Keychain via `KeychainStore`
- Service uses key derived from base URL to support multiple instances
- Token refresh is scaffolded but refresh token flow depends on server support

### GitHub OAuth
- Configure via `GitHubOAuthConfig` struct
- Requires setting Client ID in `TaigaMobileApp.swift`
- Uses `ASWebAuthenticationSession` for secure OAuth flow
- URL scheme "taiga" registered in Info.plist

### Network Security
- HTTPS only for production Taiga instances
- No certificate pinning implemented
- User can configure custom instance URLs

## API Integration

### Taiga API Base URL
- Default: `https://api.taiga.io/api/v1`
- User-configurable via login screen (stored in UserDefaults)
- URLs are normalized: tree.taiga.io automatically rewritten to api.taiga.io

### Key Endpoints
- `POST /auth` - Normal and GitHub authentication
- `POST /auth/refresh` - Token refresh
- `GET /projects` - List projects
- `GET /users/me` - Current user info
- `GET /userstories` - User stories (with project filter)
- `GET /tasks` - Tasks (with project filter)
- `GET /milestones` - Sprints
- `POST/PATCH` endpoints for creating/updating stories and tasks

### Authentication Header
```
Authorization: Bearer {auth_token}
```

## Configuration Files

### Package.swift
- Swift tools version: 5.9
- Platform: iOS 17.0+
- Three products: TaigaCore (library), TaigaUI (library), TaigaMobileApp (executable)

### project.yml
- XcodeGen configuration for generating `.xcodeproj`
- Bundle ID: `com.andrewgonzalez.tranga`
- Team ID: `U9H69CCE8H`
- Supports portrait and landscape orientations
- Registers "taiga" URL scheme for OAuth callbacks

## Development Workflow

### Adding New Features
1. Add API methods to `TaigaAPIClient` in TaigaCore
2. Add models in `Sources/TaigaCore/Models/` if needed
3. Add service methods to appropriate Service actor
4. Add ViewModel logic in TaigaUI
5. Update Views or create new SwiftUI views
6. Add tests in `Tests/TaigaCoreTests/`

### Regenerating Xcode Project
After modifying `project.yml`:
```bash
cd TaigaClient && xcodegen generate
```

## Notes for Agents

- The codebase has no third-party dependencies; use native Swift APIs
- All models are `Sendable` for Swift concurrency compatibility
- When modifying Views, always update the Preview provider
- Keychain service identifier is `"io.taiga.mobile"` - do not change without migration logic
- The app supports theming via `AppearanceMode` and `AccentColorOption` enums
- GitHub OAuth requires the developer to create their own OAuth App and set the Client ID
