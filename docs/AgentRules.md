# Agent Rules for Push365 Development

## Core Principles
1. **iOS 17+ only** - Use latest SwiftUI and SwiftData features
2. **Offline-first** - No backend, no third-party SDKs
3. **SwiftData for persistence** - All data stored locally
4. **Compile-safe changes** - Project must always build successfully
5. **Minimal implementations** - Keep code lean and focused
6. **Follow structure** - Respect App/, Models/, Services/, Views/ organization

## Development Guidelines
- Use `@Model` for SwiftData models
- Use `@MainActor` for UI-related services
- Prefer SwiftUI native components
- No ObservableObject unless specifically needed
- Follow Swift naming conventions
- Include proper error handling

## Before Committing Changes
- [ ] Project compiles without errors
- [ ] No warnings introduced
- [ ] Files placed in correct folders
- [ ] Imports are minimal and correct
