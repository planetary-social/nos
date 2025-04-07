# NIP-68 and NIP-71 Implementation Guide

This document provides an overview of the implementation for NIP-68 (Picture Posts) and NIP-71 (Video Posts) in the Nos app.

## Table of Contents

1. [Introduction](#introduction)
2. [Event Kinds](#event-kinds)
3. [Event Structure](#event-structure)
   - [Picture Post (Kind 20)](#picture-post-kind-20)
   - [Video Post (Kind 21)](#video-post-kind-21)
   - [Short Video Post (Kind 22)](#short-video-post-kind-22)
4. [Tag Structure](#tag-structure)
5. [UI Components](#ui-components)
6. [Helper Functions](#helper-functions)
7. [Testing](#testing)
8. [Future Improvements](#future-improvements)

## Introduction

NIP-68 and NIP-71 extend the Nostr protocol to support dedicated picture and video posts. This implementation allows users to create media-first content with explicit metadata for better display and accessibility.

## Event Kinds

The following event kinds have been implemented:

- **Kind 20**: Picture Post (NIP-68)
- **Kind 21**: Video Post (NIP-71)
- **Kind 22**: Short-form Video Post (NIP-71)

These are defined in `EventKind.swift`:

```swift
public enum EventKind: Int64, CaseIterable, Hashable {
    // ...
    /// Picture Post (NIP-68)
    case picturePost = 20
    
    /// Regular Video Post (NIP-71)
    case video = 21
    
    /// Short-form Video Post (NIP-71)
    case shortVideo = 22
    // ...
}
```

## Event Structure

### Picture Post (Kind 20)

Picture posts are created using the `picturePost` method in `JSONEvent+Kinds.swift`:

```swift
static func picturePost(
    pubKey: String,
    title: String,
    description: String,
    imageMetadata: [[String]],
    tags: [[String]] = []
) -> JSONEvent
```

Parameters:
- `pubKey`: Public key of the author
- `title`: Title of the picture post
- `description`: Text content/caption for the images
- `imageMetadata`: Array of image metadata tags (imeta tags)
- `tags`: Additional tags (location, content warnings, etc.)

### Video Post (Kind 21)

Regular video posts are created using the `videoPost` method with `isShortForm: false`:

```swift
static func videoPost(
    pubKey: String,
    title: String,
    description: String,
    isShortForm: Bool = false,
    publishedAt: Int? = nil,
    duration: Int? = nil,
    videoMetadata: [[String]],
    contentWarning: String? = nil,
    altText: String? = nil,
    tags: [[String]] = []
) -> JSONEvent
```

Parameters:
- `pubKey`: Public key of the author
- `title`: Title of the video
- `description`: Text content/description for the video
- `isShortForm`: Set to `false` for regular videos
- `publishedAt`: Optional Unix timestamp when the video was first published
- `duration`: Optional duration in seconds
- `videoMetadata`: Array of video metadata tags (imeta tags)
- `contentWarning`: Optional content warning
- `altText`: Optional alt text for accessibility
- `tags`: Additional tags (hashtags, etc.)

### Short Video Post (Kind 22)

Short-form video posts are created using the same `videoPost` method but with `isShortForm: true`.

## Tag Structure

### Common Tags

- `title`: The title of the picture or video post
- `content-warning`: Warning about sensitive content
- `alt`: Accessibility description
- Various hashtags or additional metadata

### Image/Video Metadata Tags

The `imeta` tag is used to describe media files:

```
["imeta", "url https://example.com/image.jpg", "m image/jpeg", "x 1200", "y 800", ...]
```

Elements within an imeta tag:
- `imeta`: Tag identifier
- `url [URL]`: URL to the media file
- `m [MIME type]`: MIME type of the media
- `x [width]`: Width in pixels
- `y [height]`: Height in pixels
- `thumb`: Optional flag for thumbnail images
- Additional metadata as needed

### Video-Specific Tags

- `published_at`: Unix timestamp when the video was first published
- `duration`: Length of the video in seconds

## UI Components

### PictureNoteCard

The `PictureNoteCard` component displays kind 20 events with:

- Title at the top
- Image gallery with paging if multiple images
- Description text below
- Action buttons at the bottom (like, repost, reply)

### VideoNoteCard

The `VideoNoteCard` component displays kinds 21 and 22 events with:

- Title at the top
- Video player with playback controls
- Description text below
- Action buttons at the bottom

## Helper Functions

To improve tag handling, several helper methods have been added to the `Event` class:

```swift
// Get all tags as a properly typed array
var tagArray: [[String]] {
    return self.allTags as? [[String]] ?? []
}

// Get value for a specific tag key
func getTagValue(key: String) -> String? {
    return tagArray.first(where: { $0.count > 1 && $0[0] == key })?[1]
}

// Get all tags with a specific key
func getTags(withKey key: String) -> [[String]] {
    return tagArray.filter { $0.count > 0 && $0[0] == key }
}

// Get all media metadata tags
func getMediaMetaTags() -> [[String]] {
    return getTags(withKey: "imeta")
}

// Extract URL from a tag element
func getURLFromTag(_ tag: [String]) -> URL? {
    if let urlString = tag.first(where: { $0.hasPrefix("url ") })?.dropFirst(4) {
        return URL(string: String(urlString))
    }
    return nil
}
```

## Testing

The implementation includes the following tests:

1. **EventTagHelpersTests.swift**
   - Tests for all tag helper methods

2. **JSONEventTests.swift**
   - Tests for `picturePost` and `videoPost` methods
   - Validates tag structure and content

## Future Improvements

1. **Caching and Performance**
   - Implement media caching for faster loading
   - Add lazy loading for videos

2. **User Experience**
   - Add dedicated composer for picture and video posts
   - Implement upload progress indicators
   - Add editing capabilities for media metadata

3. **Media Processing**
   - Add local image resizing
   - Support creating thumbnails from videos
   - Implement transcoding for better compatibility

4. **Accessibility**
   - Improve screen reader support
   - Add automatic alt text generation

5. **Advanced Features**
   - Support video chapters
   - Add multi-image carousel for picture posts
   - Implement media reactions beyond likes