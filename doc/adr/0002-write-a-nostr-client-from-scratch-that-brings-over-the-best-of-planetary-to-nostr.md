# 2. Write a Nostr client from scratch that brings over the best of Planetary to Nostr

Date: 2023-01-31

Authors: Matt Lorentz

## Status

Accepted

## Context & Problem Statement

We have decided to pivot our product from the Secure Scuttlebutt protocol to the Nostr protocol. How can we make the best Nostr client and best utilize our prior work on [Planetary](https://github.com/planetary-social/planetary-ios/)?

## Considered Options

### Fork Planetary

We could remove scuttlego, the underlying SSB library, from Planetary and replace it with a library that does equivalent things on Nostr.

**Pros**: 

- We can reuse much of Planetary's code and potentially move quicker in the short term.

**Cons**:

- The way scuttlego's database syncs with Planetary's sqlite database is inherently inefficient and unecessaary in the Nostr universe.
- The interface between scuttlego (the GoBot protocol in Swift) will likely require a lot of refactoring.
- Planetary has a lot of UIKit code we have been trying to get rid of.
- Planetary's raw sqlite access makes object observation very difficult.
- Our data model will be out of date from the beginning and will require huge refactoring in the future.

### Start Fresh and copy code from Planetary

**Pros**: 

- We can leave behind technical debt like UIKit views, homegrown sqlite data layer, SSB data model, duplicate databases.
- We can lay a better foundation for future development with an appropriate data model for Nostr.

**Cons**:

- Copying code from one project to another is manual, error prone work and loses git history.
- Changes will be harder to review because git diffs will be large.


## Decision

We will start a fresh iOS app and copy code from Planetary when appropriate.
