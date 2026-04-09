# Taiga iOS Client (SwiftUI)

Native SwiftUI starter for a third-party Taiga mobile client. It ships a lightweight Taiga REST wrapper (`TaigaCore`), SwiftUI view models and screens (`TaigaUI`), and an executable target (`TaigaMobileApp`) you can run in Xcode.

## Requirements
- Xcode 15.3+
- iOS 17.0+ simulator or device
- Swift 5.9

## Getting started
1) Open `Package.swift` in Xcode (File > Open...). Xcode will create schemes for `TaigaMobileApp` and the libraries.
2) Select the `TaigaMobileApp` scheme, choose an iOS 17+ simulator, and run.
3) Enter your Taiga credentials. The login call uses the official `POST /auth` endpoint with `type: normal` and returns the `auth_token` Taiga uses for subsequent requests.

### Configuring a self-hosted Taiga
If you host Taiga yourself, change the base URL when creating `TaigaAPIClient`:
```swift
let api = TaigaAPIClient(baseURL: URL(string: "https://yourdomain.example.com/api/v1")!)
```
Pass this instance into `AuthService` / `ProjectsService`.
The app also lets you enter the Taiga API base URL on the login screen and stores it in UserDefaults, so you can switch instances without editing code.
The public Taiga web front end is `https://tree.taiga.io/`, but its API is served from `https://api.taiga.io/api/v1`. If you type `tree.taiga.io`, the app rewrites it to the API host to avoid 405 errors.

### What’s implemented
- Normal login (`POST /api/v1/auth`) with `username`, `password`, `type: normal`.
- Bearer-authenticated `GET /api/v1/projects` to fetch project summaries.
- SwiftUI screens: login form with Taiga instance URL entry, project list with retry and loading states.
- Async/await networking, lightweight error handling, and preview stubs.

### What’s new (persistence + backlog endpoints)
- Auth token is stored in the iOS Keychain and restored on app launch; call `AuthService.logout()` to clear it.
- New models and API wrappers for user stories, tasks, and sprints (milestones) filtered by project.
- Basic backlog UI: projects list navigates to a backlog screen showing sprints, user stories, and tasks. Toolbar includes Logout.
- Token refresh scaffolded: `AuthService.authenticatedToken()` will refresh using `POST /api/v1/auth/refresh` when an `expires` value is close. citeturn0search0

### Next steps
- Add epics, notifications, attachments endpoints and richer detail screens.
- Add offline caching with `URLCache` or `SQLite` (e.g., GRDB).
- Extend UI with filtering/search and editing for stories/tasks/sprints.
- Ship CI (Xcode Cloud or fastlane + GitHub Actions) and TestFlight builds.

## Project layout
- `TaigaCore`: networking + models
  - `Networking/APIClient.swift`: REST calls for auth and projects
  - `Services/AuthService.swift`, `ProjectsService.swift`
  - `Models/`
- `TaigaUI`: SwiftUI view models + views
  - `ViewModels/AuthViewModel.swift`, `ProjectsViewModel.swift`
  - `Views/LoginView.swift`, `ProjectsListView.swift`
- `TaigaApp`: executable SwiftUI entry point (`TaigaMobileApp`, `ContentView`)
- `Tests/TaigaCoreTests`: sample unit test for auth token decoding

## API reference
- Taiga normal login docs: POST `/api/v1/auth` with body `{ "type": "normal", "username": "...", "password": "..." }`; returns `auth_token` used as Bearer for subsequent calls. citeturn0search0
