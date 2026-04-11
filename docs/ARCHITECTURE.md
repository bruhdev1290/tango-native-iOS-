# Architecture Overview

Tranga follows a modular architecture with clear separation of concerns across three Swift Package targets.

## Architecture Layers

### 1. TaigaCore (Business Logic)
Handles all backend communication and data models.

**Key Components:**
- `TaigaAPIClient`: REST API wrapper for Taiga endpoints
- `AuthService`: Authentication and token management (actor-based)
- `ProjectsService`: Project queries and management
- `ItemsService`: User stories, tasks, and sprint queries
- `KeychainStore`: Secure token storage
- Models: `AuthToken`, `ProjectSummary`, `UserStory`, `Task`, `Sprint`, `Issue`, `CurrentUser`

**Concurrency Model:**
- Services implemented as `actor` types for thread safety
- All public APIs use async/await
- Models are `Sendable` for Swift concurrency compatibility

### 2. TaigaUI (Presentation Layer)
SwiftUI views and view models using the Observation framework.

**Key Components:**
- `@Observable` ViewModels: `AuthViewModel`, `ProjectsViewModel`, `ItemsViewModel`
- `SwiftUI` Views: `LoginView`, `ProjectsListView`, `ProjectDetailView`, `AppSettingsView`
- Preview providers with mock data

**State Management:**
- Uses `@Observable` macro for reactive updates
- `@MainActor` annotations for UI thread safety
- `@Bindable` wrapper for view model bindings

### 3. TaigaApp (Entry Point)
Application initialization and root view composition.

**Key Components:**
- `TaigaMobileApp`: App delegate, theme configuration
- `ContentView`: Root view with auth state handling
- `SplashScreenView`: Onboarding animation

## Data Flow

```
User Interaction
    ↓
SwiftUI View
    ↓
@Observable ViewModel
    ↓
Service (Actor)
    ↓
APIClient
    ↓
Taiga REST API
```

## Error Handling

Custom `TaigaError` enum provides domain-specific error handling:
- `invalidCredentials`: Auth failure
- `gitHubAuthFailed(String)`: OAuth errors with details
- `http(status: Int)`: HTTP status codes
- `decoding`: JSON parsing failures
- `network(underlying: Error)`: Network errors
- `unknown`: Catch-all

## Security

- **Authentication**: Tokens stored in iOS Keychain via `KeychainStore`
- **HTTPS**: All API communication over HTTPS
- **Token Refresh**: Automatic refresh when approaching expiration
- **Keychain Service Identifier**: `"io.taiga.mobile"`

## Dependencies

- **Zero external dependencies**: Pure Swift/SwiftUI implementation
- Swift 5.9+ async/await throughout
- iOS 17.0+ (uses latest SwiftUI & Observation framework)

## Performance Considerations

- Services are actors, preventing data races
- Lazy loading of project details
- Token caching to reduce auth calls
- Efficient model decoding with `Codable`

## Future Improvements

- Offline caching with SQLite
- Background sync
- Push notifications
- Incremental search
- Pagination for large datasets
