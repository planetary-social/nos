# 7. Use SwiftSoup to parse Open Graph metadata

Date: 2024-10-02

Authors: Josh Brown

## Status

Accepted

## Context & Problem Statement

In order to display a video in portrait or landscape orientation based on its [Open Graph](https://ogp.me/) metadata, we need to parse the HTML document containing the video. The Open Graph metadata contains properties that specify the width and height of the video, and similar properties for an image that may be used as a cover image

## Considered Options

### LPMetadataProvider
[LPMetadataProvider](https://developer.apple.com/documentation/linkpresentation/lpmetadataprovider) is part of iOS and provides some Open Graph data. Unfortunately, it doesn’t provide video width or height, which is a dealbreaker here.

**Pros**:
- Built in to iOS
- Swift Concurrency API
- Single API to fetch and query data
- Type-safe API for querying

**Cons**:
- Does not provide video width or height

### XMLParser
[XMLParser](https://developer.apple.com/documentation/foundation/xmlparser) is built in to iOS and can handle valid XML documents. Not all HTML is valid XML, however, and YouTube seems to fall into this category. XMLParser was not able to get the video width and height from a YouTube HTML document.

**Pros**:
- Built in to iOS

**Cons**:
- Cannot get video width and height from YouTube HTML documents

### SwiftyOpenGraph
[SwiftyOpenGraph](https://github.com/FiveSheepCo/SwiftyOpenGraph) is a third-party package that provides a type-safe API for accessing Open Graph metadata. It can get video width and height from a HTML document, but it has additional dependencies and doesn’t seem to be widely used.

**Pros**:
- Can get video width and height from HTML
- Swift Package Manager
- Swift Concurrency API
- Single API to fetch and query data
- Type-safe API for querying

**Cons**:
- Not built in to iOS
- Has additional dependencies on SchafKit and SwiftSoup
- Not widely used (9 stars on GitHub)

### OpenGraph
[OpenGraph](https://github.com/satoshi-takano/OpenGraph) is a third-party package that provides a type-safe API for accessing Open Graph metadata. But it doesn’t currently support getting the video width and height and its documentation is somewhat lacking. We could do the work to get video height and width and submit a PR to OpenGraph, or use our own fork if needed.

**Pros**:
- Swift Package Manager
- Swift Concurrency API
- Single API to fetch and query data
- Type-safe API for querying

**Cons**:
- Not built in to iOS
- Cannot currently get video width and height from HTML

### SwiftSoup
[SwiftSoup](https://github.com/scinfu/SwiftSoup) is a third-party package that provides an API for parsing HTML. We can use it to get video width and height, though it doesn’t have a type-safe API. It’s widely used and appears to be well maintained.

**Pros**:
- Can get video width and height from HTML
- No additional dependencies
- Swift Package Manager
- Single API to fetch and query data

**Cons**:
- Not built in to iOS
- No type-safe API for querying

## Decision
We’re using SwiftSoup to parse Open Graph data from HTML.

We tried two options from the list and created PRs for each: [XMLParser](https://github.com/planetary-social/nos/pull/1504) and [SwiftSoup](https://github.com/planetary-social/nos/pull/1505). Since XMLParser didn’t work to parse the data, we decided on SwiftSoup.

We didn’t want to have to modify a package to get it to work, though we could have forked and/or submitted PRs to repositories. We wanted a tool that would work for us right away, and SwiftSoup was the one that did with zero additional dependencies.

Additional information is available for the Nos team in [this Notion doc](https://www.notion.so/nossocial/Tool-comparison-for-parsing-Open-Graph-metadata-0fe7c4703da080478ac0e96050f41b74?pvs=4), though the majority of it is covered in this ADR.