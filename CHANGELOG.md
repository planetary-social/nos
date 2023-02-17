# Changelog
All notable changes to this project will be documented in this file.

We define "Noteworthy changes" as 1) user-facing features or bugfixes 2) significant technical or architectural changes that contributors will notice. If your Pull Request does not contain any changes of this nature i.e. minor string/translation changes, patch releases of dependencies, refactoring, etc. then add the `Skip-Changelog` label. 

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Added conversion of hex keys to npub
- Add a basic New Post screen
- Save private key to keychain
- Parse and store contact list
- Add onboarding flow
- Copied MessageCard and MessageButton SwiftUI view from Planetary renaming Message to Note
- Sync authors in HomeFeedView
- Added a basic profile screen

## [0.1 Build 1]

- Parse and display Nostr events
- Read events from relays
- Sign and publish events to relays
- Add Settings view where you can put in your private key
