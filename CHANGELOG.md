# Changelog
All notable changes to this project will be documented in this file.

We define "Noteworthy changes" as 1) user-facing features or bugfixes 2) significant technical or architectural changes that contributors will notice. If your Pull Request does not contain any changes of this nature i.e. minor string/translation changes, patch releases of dependencies, refactoring, etc. then add the `Skip-Changelog` label. 

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Tap the Like button on a note you’ve already liked to remove the Like.
- Fixed issue where search results sometimes don’t appear.
- Disabled link to nip-05 server / url on author cards. 
- Fixed issue where paste menu did not appear when tapping in the Post Note view.
- Fixed intermittent crash when tapping Done after editing your profile.
- Fixed URL detection of raw domain names, such as “nos.social” (without the “http” prefix).
- Fixed the sort order of gallery media to match the order in the note.
- While composing a note, a space is now automatically inserted after any mention of a user or note to ensure it’s formatted correctly.

## [0.1.5] - 2024-02-14Z

- Fixed an issue where tapping the Feed tab did not scroll to the top of the Feed.
- Fixed an issue where tapping the Profile tab did not scroll to the top of the Profile.
- Search now starts automatically after entering three characters instead of one.

## [0.1.4] - 2024-01-31Z

- Show a message when we’re not finding search results.
- Fixed an issue where bad data in the contact list could break the home feed.
- Fixed a bug where the margins of root notes appeared incorrectly on Mac and iPad.
- Fixed a date localization issue.
- Optimized loading of the Notifications tab
- Updated suggested users for discovery tab. 
- Show the profile view when a search matches a valid User ID (npub).
- Added tabs to Profiles to filter posts.
- Fixed a bug that could cause the out of network warning to be shown on reposts in the stories view.
- Fixed a bug that prevented notes that failed to be published to be re-published again.
- Added pagination to the home feed.
- Fixed a bug that prevented reposted notes from loading sometimes.
- Fixed a bug that prevented profile photos and names from being downloaded.

## [0.1.2 (153)] - 2024-01-11Z

- Fixed a crash that sometimes occured when opening the profile view.
- Fixed a crash that sometimes occured when viewing a note.
- Migrate to Apple-native string catalog and codegen LocalizedStringResources with xcstrings-tool-plugin.
- Discover screen can now search notes by id.
- Added pagination to Profile screens.

## [0.1.1 (144)] - 2023-12-21Z

- Fixed a crash when opening the note composer.
- Fix localization of warning message when a note has been reported. (thanks @L!)
- Fixed contact list hydration bug where unfollows are not removed when follow counts do not change.
- Erase old notifications from the databse to keep disk usage low.

## [0.1 (101)] - 2023-12-15Z

- Fixed a bug where reposts wouldn't be displayed in the stories.
- Fixed a bug where the reports for authors of replies weren't being considered. 
- Localized relative times on note cards. (thanks @tyiu!)
- Added a context menu for the stories in the Home Feed to open the Profile.
- Add repost button to stories (thanks @maddiefuzz!)

## [0.1 (100)] - 2023-12-09Z

- Fixed some cases where a note's contents would never load.
- Update the color palette.
- Fix crash on Mac when opening new note view.

## [0.1 (99)] - 2023-12-07Z

- Fix profile pictures not loading after creating a new account.

## [0.1 (98)] - 2023-12-04Z

- Fixed a bug where the app could become unresponsive.

## [0.1 (97)] - 2023-12-01Z

- Added the option to copy the NIP-05 identifier when browsing a profile.
- Tapping on a tab bar icon can let you scroll to top.
- Fix an issue where reposts were not displaying correctly.

## [0.1 (96)] - 2023-11-28Z

- Fixed some performance issues for users who follow a large number of accounts.

## [0.1 (95)] - 2023-11-27Z

- Fixed a bug where a root note could be rendered as a reply
- Added the option to copy the text content while browsing a note.
- Fixed UI bugs when displaying the root note of replies.
- Keep track of read stories.
- Fix an issue where reposts were not displaying correctly.

## [0.1 (94)] - 2023-11-17Z

- Removed trailing slash from truncated URLs.
- Add a loading indicator to search results.
- Change the "Followed by" label on the profile screen to "Followers you know"
- Fixed a hang on startup.
- Fixed an issue where links couldn't be opened from the Home tab.
- Change the "Followed by" label on the profile screen to "Followers you know"
- Fixed an issue where the Profile view would always show "Following 0" for people you didn't follow.
- Fix delay in results immediately after opening the discover tab.
- Fixed the 3d card effect on the Notifications tab.
- Updated layout for search results and mention autocomplete cards.

## [0.1 (93)] - 2023-11-10Z

- Added a confirmation before reposting a note.
- Added the ability to delete your reposts by tapping the repost button again.
- Fixed some cases where deleted notes were still being displayed.
- Fixed a bug where notes, reposts, and author profiles could fail to load.
- Show truncated URLs in notes instead of hiding them completely.

## [0.1 (92)] - 2023-11-02Z

- Show reposts in stories.

## [0.1 (91)] - 2023-11-01Z

- Fix a bug where linking a Universal Name would overwrite your existing NIP-05.
- Fixed incorrect ellipsis applied to long notes.
- Changed note rendering to retain more newlines. 
- Show reposts in stories.
- Fixed a bug where notes, reposts, and author profiles could fail to load.
- Show truncated URLs in notes instead of hiding them completely.
- Keep track of read stories.
- Fixed a bug with autocorrect on Mac

## [0.1 (90)] - 2023-10-31Z

- Fixed a bug where notes, reposts, and author profiles could fail to load.

## [0.1 (89)] - 2023-10-31Z

- Added relay.causes.com to the list of recommended relays.

## [0.1 (88)] - 2023-10-27Z

- Added a content warning when a user you follow has reported the content
- Added toggles to the settings screen to disable report-based and network-based content warnings

## [0.1 (86)] - 2023-10-25Z

- Updated link previews in feed to use the stories ui with fixed height and carousel gallery. 
- Updated UI around displaying nested threads and displaying more context of conversations. 
- Changed inline images so we don't display the domain / size / file type for images
- Changed copied links to notes and authors to open in njump.me.
- Added the ability to initiate USBC transactions and check your balance if you have linked a Universal Name to your profile with an attached USBC wallet.
- Add "1 year" as an option when posting a disappearing message

## [0.1 (85)] - 2023-10-23Z

- Fixed missing secrets

## [0.1 (84)] - 2023-10-20Z

- Add Stories view to the Home Feed
- Fixed an issue where the app could become slow after searching for a user.
- Updated search results to show mutual followers and sort by the most followers in common.
- Change links to notes so that they don't display the long note id and instead it's a pretty link. 
- Redesigned the Universal Names registration flow
- Added more relays to the recommended list
- Added an icon to indicate expiring notes, and the timestamp they display is the time until they expire.

## [0.1 (83)] - 2023-10-16Z

- Fixed crash on launch
- Added a URL scheme to open the note composer: nos://note/new?contents=theContentsOfTheNote

## [0.1 (82)] - 2023-10-13Z

- Fixed a bug where profile changes wouldn't be published in some cases
- Fix a bug where the "Post" button wouldn't be shown when composing a reply on macOS
- Fix a bug where the mute list could be overwritten when muting someone
- Fixed aspect ratio on some profile photos
- Added 3d effect to note cards
- Added a URL scheme to open the note composer: nos://note/new?contents=theContentsOfTheNote

## [0.1 (81)] - 2023-09-30Z

- Fixed secrets that weren't included in build 79 and 80

## [0.1 (80)] - 2023-09-30Z

- Updated the design of the edit profile screen
- Fixed a hang on the profile screen

## [0.1 (79)] - 2023-09-22Z

- Added the ability to search for Mastodon usernames on the Discover tab. 
- Long form content is now displayed in the discover tab.
- Fixed a hang on the thread view.

## [0.1 (77)] - 2023-09-15Z

- App performance improvements

## [0.1 (76)] - 2023-09-08Z

- Minor crash fixes and optimizations

## [0.1 (75)] - 2023-09-01Z

- Fix an issue with the database cleanup script that was causing performance issues.
- Optimize loading of profile pictures

## [0.1 (73)] - 2023-08-25Z

- Fixed potential crashes when using Universal Names API.
- Fixed bug that rendered the empty notes message for a profile above the header box.
- Fixed bug that could potentially crash the app sometimes

## [0.1 (72)] - 2023-08-21Z

- Added support for pasting profile and note references when composing notes
- Pop screens from the navigation stack when tapping twice on the tab bar.
- Fixed the launch screen layout on iPad
- Fixed a small issue when mentioning profiles in the reply text box.
- Fixed a crash during onboarding
- Fixed a crash when following or muting a user
- Fixed crash when parsing malformed events.
- Fixed crash when parsing malformed contact lists.
- Added integration with our self-hosted Sentry crash reporting tool (no data shared with third parties)

## [0.1 (66)] - 2023-08-18Z

- Fixed crash when parsing malformed events.
- Fixed crash when parsing malformed contact lists.
- Added support for pasting profile and note references when composing notes
- Pop screens from the navigation stack when tapping twice on the tab bar.
- Fixed the launch screen layout on iPad
- Fixed a small issue when mentioning profiles in the reply text box.

## [0.1 (65)] - 2023-08-04Z

- Add a loading placeholder for note contents.
- Added automatic file uploads to nostr.build.
- Add list of followers and relays in the Profile screen.

## [0.1 (60)] - 2023-08-01Z

- Updated content report style based on the latest NIPs and fixed some bugs with reporting.
- Add a loading placeholder for note contents.
- Fixed the launch screen layout on iPad
- Multiple consecutive newlines will be replaced by a single new line in note content.
- Removed the screen to fill out profile information from onboarding and replaced it with a call to action in the sidebar. 
- Leading and trailing whitespace will no longer be rendered in note content.
- Removed the screen to fill out profile information from onboarding and replaced it with a call to action in the sidebar. 

## [0.1 (59)] - 2023-07-21Z

- Add a loading placeholder for note contents.
- Fixed several crashes.
- Added Dutch, Japanese, and Persian translations. Thanks matata, yutaro, and eru-desu! 
- Added some visual artists to the list of featured users.

## [0.1 (58)] - 2023-07-17Z

- Added better previews for urls shared in notes.

## [0.1 (57)] - 2023-07-17Z

- Fixed an issue where Nos couldn't find the user's key on startup.
- Fixed an issue where you could have duplicate relays: one with a trailing slash and one without.

## [0.1 (56)] - 2023-07-13Z

- Fixed high cpu usage when the app is idle

## [0.1 (55)] - 2023-07-12Z

- Fixed several bugs around muting users
- Added the number of connected relays at the top right corner of the Home Feed.
- Fixed a bug where expired messages could be published to relays that doesn't support them
- Added support for push notifications.

## [0.1 (53)] - 2023-07-03Z

- Added beta integration with the Universal Name System. Edit your profile to link your Universal Name to your Nostr profile.
- Updated design of the relay selector

## [0.1 (52)] - 2023-07-03Z

- Prevent muted authors from appearing in the Discover screen
- Added a confirmation dialog when deleting a note.

## [0.1 (51)] - 2023-06-16Z

- Updated design of the relay selector
- Fixed an issue where the Discover tab wouldn't show new content for a while after upgrading from build 49.

## [0.1 (50)] - 2023-06-15Z

- Added code to show the Discover tab when we haven't downloaded the user's follow list yet (like on first login or app reinstall).
- Improved reliability of loading reposts, user photos, and names.
- Fixed a bug where tapping on a note would open the associated image instead of the thread view.
- Fixed a bug where profile pages would not load in some cases.
- Improved performance of the relay manager.

## [0.1 (49)] - 2023-06-12Z

- More small optimizations to relay traffic and event parsing.

## [0.1 (48)] - 2023-06-12Z

- Requesting fewer events on Home and Discover tab to reduce the load on the db.

## [0.1 (47)] - 2023-06-09Z

- Improved performance of the relay manager.

## [0.1 (46)] - 2023-06-06Z

- Add the ability to report notes and profiles using NIP-32 labels and NIP-69 classification.
- Fixed a crash which occurs on some versions of MacOS when attempting to mention other users during post creation.
- Add the ability to search for users by name from the Discover tab
- Fixed a bug where the note options menu wouldn't show up sometimes.
- Strip whitespace and newline characters when parsing search box input on discover screen as npub.

## [0.1 (44)] - 2023-05-31Z

- Fixed several causes of profile pictures and reposts showing infinite spinners.
- Links to notes or profiles are now tappable.
- Filter logged user from Discover screen.
- Improved performance of posting notes.

## [0.1 (43)] - 2023-05-23Z

- Added German translations (thanks Peter!).
- Updated support email to support@nos.social
- Improved recognition of mentions inside a post

## [0.1 (42)] - 2023-05-16Z

- Added support for mentioning other users when composing a note.
- Fixed a bug where expired messages could be redownloaded from relays that don't delete them.
- Fixed a bug where you couldn't view the parent note of a reply when it was displayed at the top of the Thread view.

## [0.1 (41)] - 2023-05-11Z

- Fix link color on macOS

## [0.1 (40)] - 2023-05-10Z

- Add support for expiration dates when composing notes (please note: messages are not guaranteed to be deleted by relays or other apps)
- Increased the contrast of text in light mode
- Open links in an in-app web browser instead of Safari
- Fixed link detection in notes for URLs without a scheme (i.e. "https://")
- Made the reply button on notes easier to tap, and it now presents the keyboard when tapped.
- Increased the tap size of the ellipsis button on note cards.
- Added Spanish translations (thanks Martin!)
- Updated app icon
- Nos now displays kind 30023 long-form blog posts in the home and profile feeds.

## [0.1 (39)] - 2023-05-02Z

- Improved performance of loading replies
- The notifications tab now request more events from relays

## [0.1 (38)] - 2023-04-28Z

- Made the routine to delete old events more efficient and prevent it from deleting our own events. 
- Fixed a bug where you could post the same reply multiple times.

## [0.1 (37)] - 2023-04-27Z

- Performance improvements
- Added support for reposting notes.
- Fixed a bug where you could post the same reply multiple times.
- Fixed a bug where the user's follow list could be erased on the first launch after importing a new key.

## [0.1 (36)] - 2023-04-25Z

- Added support for reposting notes.
- Added Brazilian Portuguese translations (thanks Andressa!).
- Fixed the French and Traditional Chinese translations.
- Fixed a bug where the user's follow list could be erased on the first launch after importing a new key.
- Fixed a bug where you could post the same reply multiple times.
- Fixed an issue where profile pictures could be rendered with the wrong aspect ratio.

## [0.1 (35)] - 2023-04-19Z

- Added French translations. Thank you p2x@p2xco.de!
- Added Chinese (Traditional) and updated Chinese (Simplified) translations. Thank you rasputin@getalby.com!
- Added a logout button in the Settings menu.
- Minor performance improvements on Thread and Discover views.
- Updated the default list of users shown on the Discover tab.
- Fixed a bug where muted authors would show up on the Discover tab.
- Added an initial loading indicator when you first open the Home or Discover tabs.
- Added a logout button in the Settings menu.
- Fixed a bug where notes would be truncated but the Read More button would not be shown.
- Scrolling performance improvements
- Fixed a bug where notes would be truncated but the Read More button would not be shown.

## [0.1 (33)] - 2023-04-17Z

- Added a button to share the application logs in the Settings menu
- Automatically attach debug logs to support emails

## [0.1 (32)] - 2023-04-14Z

- More performance improvements on the Home tab.

Note:
- In this build you have to pull-to-refresh if you want to see new notes after the initial load of the Home or Discover tabs. 

## [0.1 (31)] - 2023-04-13Z

- Added a button to view raw event JSON in the options menu on notes.
- Fixed notes saying "so-and-so posted" at the top when it should say "so-and-so replied".
- Added code to load the note being replied to if we don't have it. 
- Improved performance on the home feed

## [0.1 (30)] - 2023-04-10Z

- Fixed a bug where the Read More button would show on notes when it didn't need to.
- Added Chinese (Simplified) translations (thanks rasputin@getalby.com!)
- Nos now requests delete events from relays.

## [0.1 (28)] - 2023-04-07Z

- Made all the built-in text in the app translatable. If you would like to help translate Nos let us know by emailing support@nos.social.

## [0.1 (27)] - 2023-04-05Z

- Minor performance improvements
- Fixed an occasional hang when publishing

## [0.1 (26)] - 2023-04-03Z

- Minor performance improvements on the Feed and Discover tabs

## [0.1 (25)] - 2023-03-31Z

- Fixed a bug where reply counts were displaying translation keys instead of the count

## [0.1 (24)] - 2023-03-31Z

- Added Crowdin integration for translation services. If you would like to help us translate Nos drop us a line at 
support@nos.social.
- Fixed several crashes.
- Fixed issue where the like button didn't turn orange when pressed.
- Fixed an issue where likes to replies were counted towards the root note.
- Added more aggressive caching of images.
- Minor performance improvements - more to come!

## [0.1 (23)] - 2023-03-25Z
- Add the option to copy web links on profile pages and notes.

## [0.1 (22)] - 2023-03-23Z
- Fixed a bug in the list of people you are following, where tapping on any name would show your own profile.

## [0.1 (21)] - 2023-03-23Z
- Fixed a bug where the user's profile name was not set after onboarding.
- Added a demo of the Universal Namespace when setting up your profile. 

## [0.1 (20)] - 2023-03-22Z
- Fixed some bugs in Universal Name login flow (onboarding flow fixes forthcoming)

## [0.1 (19)] - 2023-03-22Z
- Added a link to nostr.build on the New Note screen
- Added a demo flow for setting up a Universal Name on the Edit Profile screen.

## [0.1 (18)] - 2023-03-20Z
- Show the number of likes on notes

## [0.1 (17)] - 2023-03-20Z
- Minor performance improvements

## [0.1 (16)] - 2023-03-19Z
- Hide the text in private key text fields
- Hide replies from muted users
- Fixed an issue where your own replies would be shown on the notificaitons tab
- Added a launch screen
- Various styling updates
- Added an About screen to the side menu
- Added a Share Nos button to the side menu 

## [0.1 (15)] - 2023-03-18Z
- Added the ability to browse all notes from a single relay on the Discover tab.
- Added the ability to post a note to a single relay from the New Note screen.
- Support likes as described in NIP-25, make sure reply and parent likes are correct
- Show "posted" and "replied" headers on NoteCards
- Navigate to replied to note when tapping on reply from outside thread view
- Search by name on Discover view
- Fixed cards on the Discover tab all being the same size.
- Fixed a crash when deleting your key in Settings

## [0.1 (14)] - 2023-03-16Z
- Nos now reads and writes your mutes the mute list shared with other Nostr apps.

## [0.1 (13)] - 2023-03-15Z
- Fix all thread replies showing as out of network on first launch after installation.

## [0.1 (12)] - 2023-03-15Z
- Added NIP-05 field to Edit Profile page, lookup users using NIP-05 names in discover tab, tapping the NIP-05 name opens the domain in a new window.
- Delete notes
- More performance improvements centered around our relay communication
- Fix invisible tab bar
- Made placeholder text color same for all fields in profile edit view
- Add basic image rendering in Note cards
- UNS Support on Profile page
- Fix onboarding taps at bottom of screen causing screen to switch

Known Issues:
- Deleting your key in Settings causes the app to crash. But you are correctly taken into onboarding after relaunch.

## [0.1 (11)] - 2023-03-14Z
- Fixed thread view saying every reply is out of network
- reduced the number of requests we send to relays
- improved app performance
- fixed showing empty displayNames when name is set

## [0.1 (10)] - 2023-03-14Z
- Display a user's NIP-05 identifier on the profile page after making a web request to verify that it is correct 
- Fix blank home feed during first launch

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
- Open an email compose view controller for support@nos.social 
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
