# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands
- Build project: `xcodebuild -project Nos.xcodeproj -scheme Nos`
- Run unit tests: `xcodebuild test -project Nos.xcodeproj -scheme NosTests`
- Run performance tests: `xcodebuild test -project Nos.xcodeproj -scheme "NosPerformance Tests"`
- Run single test: `xcodebuild test -project Nos.xcodeproj -scheme NosTests -testPlan UnitTests -only-testing:NosTests/<TestClassName>/<testMethodName>`
- Clean build folder: `xcodebuild clean -project Nos.xcodeproj -scheme Nos`

## Code Style Guidelines
- **Architecture**: Follow MVC pattern with single source of truth (ADR-0004)
- **Types**: Prefer protocol conformance (Sendable, Identifiable, Equatable, Codable, Hashable)
- **Imports**: Group imports with Foundation/SwiftUI first, then alphabetically
- **Naming**: Use descriptive camelCase for variables/methods, PascalCase for types
- **Error Handling**: Use specific error types (e.g., EventError, AuthorListError) 
- **Testing**: Test files should mirror app structure in NosTests directory
- **Extensions**: Use extensions to organize functionality by protocol/feature
- **Comments**: Provide documentation comments for public APIs
- **Async**: Use Swift concurrency (async/await) and Task for asynchronous code

## Git Workflow
- Protected main branch (ADR-0005)
- Enabled GitHub merge queue (ADR-0006)
- Create feature branches for all changes