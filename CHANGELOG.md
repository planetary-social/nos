# Changelog
All notable changes to this project will be documented in this file.

We define "Noteworthy changes" as 1) user-facing features or bugfixes 2) significant technical or architectural changes that contributors will notice. If your Pull Request does not contain any changes of this nature i.e. minor string/translation changes, patch releases of dependencies, refactoring, etc. then add the `Skip-Changelog` label. 

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
- Display a user's NIP-05 identifier on the profile page after making a web request to verify that it is correct 

## [0.1 (9)] - 2023-03-14Z
- Fixed a crash on launch when relay model was outdated.
- Fix your own posts showing as outside your network on a fresh install. 
- Add self-hosted PostHog analytics
- Render mentions on notifications tab
- Copy note text

Known issues:
- You may have to force quit the app and restart it to see everyone you follow on the Home Feed.

## [0.1 (8)] - 2023-03-13Z
- Fix translucent tab bar in the simulator.
- Connect to more relays to get user relay list after importing a key during onboarding
- Fix some bugs in thread views
- Show placeholder cards for messages outside 2 hops and allow the user to reveal them
- Support deprecated reply #e tag format
- Fixed an issue where older contact list and metadata events could overwrite new ones
- Styled onboarding views

## [0.1 (7)] - 2023-03-10Z
- Use only relays added in RelayView for sending and receiving events
- Add PostHog analytics
- Render note mentions in NoteCard
- Open an email compose view controller for support@planetary.social 
- Fix duplicate note on a new post
- Add mute functionality
- Publish relay changes
- Recommended / default relays
- Added colors and Clarity City font throughout the app
- Show Discover tab after onboarding
- Fix crash on Mac
- Improved profile photo loading and added a cache
- Added code to compute a sensible default number of columns on the Discover tab
- Replaced moved relays tab to side menu, added New Post and Profile tabs
- Make links on notes tappable
- Fix newlines not rendering on notes
- Added timestamp to notes
- Update Discover feed algorithm to include people 2 hops from you.
- Fix infinite spinners on some avatars
- Edit profile

## [0.1 (6)] - 2023-03-08Z

- Fixed follow / unfollow sync
- Reduced number of REQ sent to relays
- Request profile metadata for users displayed on the Discover tab
- Cleanup RelayService
- Render user avatar on Profile screen
- Added support for threads in reply views
- Retry failed Event sends every 2 minutes (max 5 retries)
- Add basic notifications tab
- Filter the Home Feed down to root posts
- The profile view requests the latest events and metadata for the given user from the relays
- Add the ellipsis button to NoteCard and allow the user to copy the NIP-19 note ID of a note.
- Enabled button to copy user ID on Profile View
- Fixed UI freezes when using many relays by moving event processing to a background thread.
- Add a search bar to the discover tab that users can use to look up other users.
- On relay remove, send CLOSE to all subs then disconnect and delete socket
- Render user mentions in NoteCard
- Replace the warning message to tell the user never to share their private key with anyone.

## [0.1 (5)] 2023-03-02 

- Added a Discover tab that shows all events from all relays.
- Core Data will now be wiped whenever we change the data model, which is often. This speeds up our development process, but you will have to re-enter your relays when this happens.
- Change the home feed so that it shows the CurrentUser's notes always.
- Preload sample_data into core data for DEBUG builds
- Added a screen to show all the replies to a note.
- Fixed empty home feed message so it doesn't overlay other views
- Change settings and onboarding to accept nsec-format private key
- Fixed app crash when no user is passed to HomeFeedView initializer
- Added ability to post a reply in thread view.
- Fixed READ MORE Button
- In the Discover tab, display a feed of interesting people

## [0.1 (4)] - 2023-02-24

- Added ability to delete relays on the Relays screen.
- Fix events not being signed correctly with a key generated during onboarding.
- Verify signatures on events.
- Request only events from user's Follows
- Follow / unfollow functionality
- Calculate reply count and display in NoteCard

## [0.1 (3)] - 2023-02-20Z

- Sync authors in HomeFeedView
- Added AvatarView for rendering profile pictures on NoteCards

## [0.1 (2)]

- Added conversion of hex keys to npub
- Add a basic New Post screen
- Save private key to keychain
- Parse and store contact list
- Add onboarding flow
- Copied MessageCard and MessageButton SwiftUI view from Planetary renaming Message to Note
- Added a basic profile screen

## [0.1 (1)]

- Parse and display Nostr events
- Read events from relays
- Sign and publish events to relays
- Add Settings view where you can put in your private key
- Added tab bar component and side menu with profile
