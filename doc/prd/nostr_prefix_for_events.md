# Product Requirements Document: Adding nostr: Prefix to Nevent IDs

## Overview
This document outlines the requirements for enhancing the Nos app to consistently add the "nostr:" prefix to nevent strings in posts, particularly in quote posts. The enhancement will ensure compliance with Nostr protocol standards (NIP-01), improve compatibility with other Nostr clients, and enhance the user experience by making event links more consistent and recognizable.

## Background
The Nostr protocol uses bech32-encoded strings with specific prefixes to identify different types of entities in the ecosystem. For events, the prefix is "nevent1" (resulting in strings like "nevent1..."). According to the Nostr specification, these identifiers should be made clickable by adding the "nostr:" URI scheme prefix (resulting in "nostr:nevent1...").

The NIP-01 specification explicitly recommends using the "nostr:" URI scheme for referencing events and profiles to ensure proper client interoperability. Currently, the Nos app inconsistently handles the "nostr:" prefix in event identifiers. When users share or quote posts, event references may lack the "nostr:" prefix, which affects compatibility with other Nostr clients and reduces the usability of quoted or referenced content.

## Current Implementation Analysis

After examining the code, I've identified the following key components:

1. **NoteParser.swift**: 
   - The `replaceNostrEntities` method already recognizes and handles both prefixed and non-prefixed Nostr entities (including nevent identifiers)
   - In the `replaceNostrEntities` method at line 148, the regex pattern correctly matches entities with or without the "nostr:" prefix
   - The parser handles and processes event references correctly but doesn't consistently use the "nostr:" prefix in the output

2. **NoteComposer.swift**:
   - In `postText` at line 330-334, when quoting a note, the composer does add the "nostr:" prefix to the quoted note ID
   - The quoted note handling is properly formatted with the "nostr:" prefix

3. **DeepLinkService.swift**:
   - Already includes the "nostr:" scheme in its supported URL schemes
   - Properly extracts entity identifiers from URLs with the "nostr:" prefix using the `unformattedRegex` pattern
   - Correctly handles and routes users when clicking on nostr: links

4. **Router.swift**:
   - Has functionality to open and handle various types of URLs, including those with the "nostr:" prefix

## Remaining Issues

1. While quoted notes already have the "nostr:" prefix added, there's inconsistency in:
   - How event references are displayed when parsed from existing content
   - How event links are generated in markdown link output

2. The NoteParser's `replaceNostrEntities` method currently converts identified event references to markdown links with the format `[Link to Note](%hex)` rather than preserving or adding the "nostr:" prefix.

## Goals
1. Ensure all nevent identifiers in posts (especially quote posts) include the "nostr:" prefix
2. Improve link detection and handling for event references
3. Maintain backward compatibility with existing event references without the prefix
4. Ensure that when users click on "nostr:nevent1..." links, they are properly routed within the app

## Non-Goals
1. Changing how other Nostr identifiers (npub, note, nprofile, etc.) are handled
2. Modifying the deep link handling architecture
3. Changing the visual representation of event links in posts

## Requirements

### 1. Update Note Parser
The NoteParser class needs to be updated to consistently add the "nostr:" prefix to nevent identifiers, in alignment with the NIP-01 specification.

- The primary change needed is in the `replaceNostrEntities` method around line 182:

```swift
// Current implementation:
return "\(prefix)[\(String(localized: .localizable.linkToNote))](%\(rawEventID))"

// Should be changed to ensure the "nostr:" prefix is preserved and standardized
```

- Modify the `replaceNostrEntities` method to ensure that when nevent identifiers are processed, the "nostr:" prefix is always included in the markdown link generation
- Update the regex pattern used for detection to properly identify both prefixed and non-prefixed event identifiers
- When generating markdown links for events, ensure the link includes the "nostr:" prefix
- When processing event mentions in text, ensure the corresponding `e` tags are properly added to the event tags array
- Maintain compatibility with legacy non-prefixed event references while promoting the use of the prefixed format

### 2. Update Deep Link Handling
The DeepLinkService needs to reliably handle event links with the "nostr:" prefix.

- Ensure the `handle` method in DeepLinkService properly extracts event IDs from URLs with the "nostr:" scheme
- Update the regular expression in the DeepLinkService to reliably capture both prefixed and non-prefixed event identifiers

### 3. Repost Functionality Enhancement
When reposting or quoting notes, ensure proper prefix handling.

- Update any code that generates quotes or reposts to include the "nostr:" prefix for event references
- Verify that the repost preview properly displays and links event references

### 4. Router Updates
Ensure the Router correctly handles links with the "nostr:" prefix.

- Verify Router.open(url:) properly handles event URLs with the "nostr:" prefix
- Add or update routing logic to extract the event ID correctly from prefixed URLs

## Technical Specification

### Code Changes Required

1. **NoteParser.swift**:
   - Update the markdown link generation in `replaceNostrEntities` (line ~182) to consistently include the "nostr:" prefix for nevent identifiers
   - Ensure the link text and URL components properly handle and preserve the prefix
   - Update the regex pattern in `replaceNostrEntities` to ensure it recognizes both "nostr:nevent1..." and "nevent1..." formats
   - Implement proper handling of both formats while standardizing on the prefixed format for newly generated content

2. **DeepLinkService.swift**:
   - Review and update the regular expression in the `handle` method to properly extract event IDs from URLs with the "nostr:" scheme
   - Ensure the routing logic correctly handles nested prefixes (e.g., "nostr:nostr:nevent1...")
   - Align handling with the NIP-01 specification for Nostr URI scheme handling

3. **Router.swift**:
   - Verify the URL handling logic in `open(url:)` properly processes event references with the "nostr:" prefix
   - Ensure consistent handling of both prefixed and non-prefixed formats for backward compatibility

### Data Flow
1. User creates a post that includes or references another note (especially quotes)
2. The NoteParser adds the "nostr:" prefix to any nevent identifiers
3. When displayed, the post shows properly formatted clickable links
4. When a user taps an event link, the Router extracts the event ID and navigates to the appropriate note view

## Tests Required

### Unit Tests

1. **NoteParserTests**:
   - Add a test that verifies nevent links in output have the "nostr:" prefix
   - Add a test that verifies clicking on a "nostr:nevent1..." link properly navigates to the note
   - Test that the parser correctly adds "nostr:" prefix to nevent identifiers
   - Test that the parser correctly handles already prefixed identifiers (e.g., "nostr:nevent1...")
   - Test that the parser generates proper markdown links for event references
   - Test that the parser correctly extracts event references and adds corresponding `e` tags
   - Test various edge cases (multiple events, mixed with other content, etc.)
   - Test the correct handling of event references according to the NIP-01 specification
   - Confirm that event reference extraction is properly handled with or without the prefix

2. **DeepLinkServiceTests**:
   - Test handling of URLs with the "nostr:" scheme
   - Test extraction of event IDs from different URL formats
   - Test handling of nested prefixes

3. **RouterTests**:
   - Test routing behavior for event links with and without the "nostr:" prefix
   - Test proper navigation to note views based on event links

### Integration Tests

1. **Event Processing**:
   - Test end-to-end flow of creating posts with event references
   - Verify that quoted events are properly displayed and clickable
   - Test handling of incoming events with different formats of event references
   - Ensure proper tag generation when referencing events as described in NIP-01
   - Verify that when reposting/quoting a note, the proper "nostr:" prefix is added to event references
   - Test interaction with other Nostr clients to verify interoperability
   - Verify that quoted events are properly displayed with the "nostr:" prefix
   - Verify routing behavior when clicking on event links

### UI Tests

1. **Quotes and Reposts**:
   - Test creating a quote post and verify the event reference is properly displayed
   - Test clicking on event references and verify navigation to the correct note view
   - Test copying and pasting event IDs in different formats

## Success Metrics
1. All event references in posts include the "nostr:" prefix
2. Users can click on any event reference (with or without the prefix) and be taken to the correct note view
3. Existing content continues to work correctly with the updated parsing logic
4. No regression in parsing or rendering of other Nostr entities

## Implementation Plan
1. Update the `replaceNostrEntities` method in NoteParser.swift to ensure consistent use of the "nostr:" prefix
2. Add appropriate unit tests to verify correct behavior
3. Test integration with existing components
4. Update the CHANGELOG.md to document this enhancement

## Timeline
1. Implementation: 1 day
2. Testing: 1 day 
3. Code review and bug fixes: 1 day
4. Release: Part of the next regular app update

## Future Considerations
1. Consider applying similar consistency to other Nostr identifiers (npub, nprofile, etc.)
2. Evaluate adding visual indicators for different types of Nostr entities in posts
3. Consider enhancing the preview of quoted content for better user experience
4. Implement support for additional NIP specifications that may extend or modify how event references work
5. Consider auto-detection and conversion of event references in plain text to properly formatted "nostr:" links
6. Explore enhanced visualization of quoted content with richer preview cards

## Documentation
Update the following documentation as part of this change:
1. Add comments to the NoteParser and DeepLinkService code explaining the prefix handling and NIP-01 compliance
2. Update the CHANGELOG.md to document this enhancement
3. Document the behavior in the appropriate project wiki or documentation repository
4. Include references to the relevant Nostr specification (NIP-01) in code comments and documentation
5. Add notes in the code about handling both prefixed and non-prefixed formats for backward compatibility