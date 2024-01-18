# 3. Use Core Data for persistence

Date: 2023-01-31

Authors: Matt Lorentz

## Status

Accepted

## Context & Problem Statement

We are prototyping a new Nostr app, and we need a database. All Nostr data exists on relays, so this database is mostly a cache, although we will probably want to store other data to i.e. retry publishing events that failed to publish.

Since SwiftUI is our default choice for building screens we want something that integrates well with it's observation features. We anticipate fetching objects in complex ways and supporting various feed algoritms like we do in Planetary, so a relational database seems like a good choice.

## Considered Options

### Raw SQLite

**Pros**:

- We have done this already in Planetary and can probably reuse some code.
- You have full control over the database and table structure.
- We can avoid complexity that typically comes with an ORM library.

**Cons**:

- We have to work hard to optimize our code - homegrown concurrency model, adding the right indexes, running database maintenance scripts, etc.
- We have to write a custom observation layer so that our views can efficiently redraw when the database changes.

### Core Data

**Pros**:

- Integrates well with SwiftUI observation via @FetchRequest.
- Widely used - many educational and troubleshooting resources.
- Built in concurrency model.
- Highly optimized.
- Developed by Apple.

**Cons**:

- Extremely complex. Includes features we may not use like iCloud integration, multiple persistent stores, undo management.
- Very old. Some APIs have been updated for Swift but there are still many old Objective-C classes and APIs we need to interact with.
- Tends to crash when used incorrectly - especially around concurrency.

### Realm

**Pros**:

- Widely used and well supported.
- Well optimized

**Cons**:

- Doesn't support SwiftUI observation.

## Decision

We will use Core Data for our persistence layer, mostly so we can take full advantage of SwiftUI's rapid prototyping features and single-source-of-truth architecture.
