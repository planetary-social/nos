# NIP-68/71 Implementation Improvement Plan

This document outlines the plan to improve the implementation of NIP-68 (Picture Posts - kind 20) and NIP-71 (Video Posts - kinds 21 & 22) in the Nos app.

## Overview

The current implementation adds support for the following Nostr event kinds:
- Kind 20: Picture Post (NIP-68)
- Kind 21: Video Post (NIP-71)
- Kind 22: Short-form Video Post (NIP-71)

While the core functionality is in place, there are several areas that could be improved for better code maintainability, performance, and user experience.

## Improvement Checklist

### Code Structure Issues

- [x] **1. Remove duplicate `videoPost` method in JSONEvent+Kinds.swift**
  - There are two identical method definitions
  - Keep only one implementation to avoid confusion

- [x] **2. Simplify constructor initialization in PictureNoteCard and VideoNoteCard**
  - Refactor the verbose initialization to a more concise version using tuples
  - Makes the code more maintainable

### UI and UX Improvements

- [x] **3. Add better error handling in VideoNoteCard**
  - Add a loading indicator during video loading
  - Add a fallback UI when a video URL is invalid
  - Improve the user experience when videos don't load

- [x] **4. Fix bug in conditional rendering in NoteCard.swift**
  - Correct the condition that uses `EventKind.picturePost.rawValue` for VideoNoteCard
  - Should be checking for `EventKind.video.rawValue` instead

### Refactoring for Better Maintainability

- [x] **5. Implement helper methods for tag parsing**
  - Create an extension to `Event` with helper methods
  - Add `getTagValue`, `getImageMetaTags`, and `getURLFromTag` methods
  - Refactor PictureNoteCard and VideoNoteCard to use these helpers

- [x] **6. Improve RepliesLabel error handling**
  - Add better error handling for AttributedString creation
  - Add fallback when markdown parsing fails
  - Log errors for debugging

- [x] **7. Optimize performance in RepliesLabel**
  - Add throttling mechanism to avoid excessive recomputation
  - Consider using a Combine-based approach for more efficient updates

### Type Safety and Resilience

- [x] **8. Add type safety improvements for tag arrays**
  - Add a computed property for tag arrays to avoid repeated casting
  - Make the code more resilient to type issues
  - ✅ Implemented as part of item #5 with the `tagArray` computed property

### Testing and Documentation

- [ ] **9. Add unit tests for new event kinds**
  - Create tests for parsing kind 20, 21, and 22 events
  - Test the VideoNoteCard and PictureNoteCard with various inputs
  - Ensure edge cases are properly handled

- [ ] **10. Update documentation and comments**
  - Add clear documentation for the new event kinds
  - Document the tag structure expected for each kind
  - Add examples in comments

## Implementation Progress

We've successfully completed items 1-8 of our improvement checklist:

1. ✅ Removed duplicate `videoPost` method and improved documentation
2. ✅ Simplified constructors using tuple assignment
3. ✅ Added better error handling and loading states to VideoNoteCard
4. ✅ Fixed conditional bug in NoteCard.swift that was showing wrong card type
5. ✅ Implemented helper methods for tag parsing
6. ✅ Improved RepliesLabel error handling with fallbacks
7. ✅ Added throttling to avoid excessive avatar computations
8. ✅ Added type safety improvements with tagArray computed property

The remaining tasks focus on testing and documentation to ensure our implementation is robust and maintainable.

## Implementation Approach

For each item in the checklist:

1. Make the code changes for the specific improvement
2. Test the changes locally
3. Verify that the UI works as expected
4. Check for regressions in related functionality
5. Commit the changes with a clear commit message

This methodical approach will ensure that the implementation is robust and maintainable while minimizing the risk of introducing new bugs.