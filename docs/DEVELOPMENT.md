# Development Guide

This document provides setup and development instructions for the Tranga iOS app.

## Prerequisites

- macOS 12 or later
- Xcode 15.3 or later
- Swift 5.9+
- iOS 17.0+ simulator or device

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/bruhdev1290/tango-native-iOS-.git
cd tango-native-iOS-
```

### 2. Build the App
```bash
xcodegen generate  # Generate Xcode project from project.yml
xcode Tranga.xcodeproj
```

Or using Swift Package Manager:
```bash
swift build -c debug
```

### 3. Run on Simulator
```bash
# Using Xcode: Select Tranga scheme, choose iPhone simulator, and press Run

# Or using xcodebuild:
xcodebuild -scheme Tranga -configuration Debug -sdk iphonesimulator build
xcrun simctl install booted ./build/Debug-iphonesimulator/Tranga.app
xcrun simctl launch booted com.andrewgonzalez.tranga
```

## Project Structure

```
├── Package.swift           # Swift Package manifest
├── project.yml             # XcodeGen configuration
├── Sources/
│   ├── TaigaCore/          # Core business logic & networking
│   ├── TaigaUI/            # SwiftUI views and view models
│   └── TaigaApp/           # App entry point
├── Tests/                  # Unit tests
├── Tranga.xcodeproj/       # Generated Xcode project
├── docs/                   # Documentation
└── .github/                # GitHub configuration files
```

## Building for Release

```bash
xcodebuild -scheme Tranga -configuration Release -sdk iphoneos build
```

## Testing

```bash
swift test
```

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

## Troubleshooting

### Build Fails with "No Account for Team"
This means Xcode can't find your Apple ID. Sign into Xcode by:
1. Opening Xcode
2. Going to Preferences → Accounts
3. Adding your Apple ID
4. Enabling automatic signing

### App Crashes on Launch
Check the Xcode console for error messages. Common issues:
- Missing Keychain permissions
- Invalid Taiga API URL
- Network connectivity issues

## Resources

- [Taiga API Documentation](https://docs.taiga.io/api/)
- [SwiftUI Documentation](https://developer.apple.com/xcode/swiftui/)
- [Swift Concurrency Guide](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency)
