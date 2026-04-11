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
- Normal login (`POST /api/v1/auth`) with `username`, `password`, `type: normal` and GitHub OAuth.
- Bearer-authenticated `GET /api/v1/projects` with member filtering for your projects.
- SwiftUI screens: login form with Taiga instance URL entry, projects home screen, backlog screens, activity feed.
- Async/await networking, lightweight error handling, and preview stubs.
- Token persistence in iOS Keychain with automatic token refresh.
- **Backlog Management**: Full CRUD for user stories, tasks, and issues with inline editing.
- **Notifications**: Local push notifications for assigned items and new project activity.
- **Activity Aggregation**: Smart deduplication and timestamp-based sorting for cross-project feeds.
- **Item State**: Complete/incomplete marking with AppStorage persistence.
- **Settings**: Dark/light/system appearance, accent color customization, notification preferences, GitHub link.

### What’s new (persistence + backlog endpoints)
- Auth token is stored in the iOS Keychain and restored on app launch; call `AuthService.logout()` to clear it.
- New models and API wrappers for user stories, tasks, and sprints (milestones) filtered by project.
- Basic backlog UI: projects list navigates to a backlog screen showing sprints, user stories, and tasks.
- Settings now includes an `Account` section with `Logout` and a `GitHub` submenu linking to the project repository: `https://github.com/bruhdev1290/tango-native-iOS-`.
- Token refresh scaffolded: `AuthService.authenticatedToken()` will refresh using `POST /api/v1/auth/refresh` when an `expires` value is close.

### Recent Major Features
- **Liquid Glass UI**: Beautiful glassmorphic bottom tab bar with smooth animations between Home and Activity tabs.
- **Activity Feed**: Comprehensive cross-project activity aggregation showing assigned items and items from member projects, sorted by timestamp with deduplication.
- **My Work Section**: Horizontal carousel on home screen showing all items assigned to the user across all projects.
- **Project Photos**: Automatic fetching and display of project logos/photos with intelligent URL fallback and initials display.
- **Item Lifecycle Management**:
  - Create new user stories, tasks, and issues with full attachment support
  - Edit existing items with inline updates
  - Mark items as complete/incomplete with client-side persistence
  - Delete items with confirmation dialogs and proper error handling
- **On-Device Notifications**: Receive local notifications for newly assigned items and new items added to member projects. Customizable via Settings > Notifications.
- **Activity Filters**: Filter the Activity feed by item type (Stories/Tasks/Issues) and by source (Assigned to Me/In My Projects). Accessible via the slider icon on the Activity tab.
- **Search**: Search projects you're a member of with autocomplete.

### Next steps
- Add epics, kanban board views, and comments functionality.
- Add offline caching with `URLCache` or `SQLite` (e.g., GRDB).
- Extend search to include issues and cross-project search.
- Add bulk operations (multi-select, batch assign, batch tag).
- Ship CI (Xcode Cloud or fastlane + GitHub Actions) and TestFlight builds.
- Add undo/trash recovery for deleted items.
- Implement activity feed date-grouped sections (Today/Yesterday/Earlier).
- Add notification persistence and in-app notification center.

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
- Taiga normal login docs: POST `/api/v1/auth` with body `{ "type": "normal", "username": "...", "password": "..." }`; returns `auth_token` used as Bearer for subsequent calls. 
