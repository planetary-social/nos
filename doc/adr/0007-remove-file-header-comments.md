# 7. Remove File Header Comments

Date: 2024-03-08

Authors: Josh Brown

## Status

Accepted

## Context & Problem Statement

File header comments contain duplicate information that can be found elsewhere and are often inaccurate and confusing.

What do I mean by file header comments? Here’s one:

```
//
//  ExcellentChoiceSheet.swift
//  Nos
//
//  Created by Martin Dutra on 6/3/24.
//
```

Questions and answers:

Do we need to know that this is `ExcellentChoiceSheet.swift`? No. In any context, we’ll have the file name, often in multiple places.

What happens when the file name changes? Often, the header comment is not updated and we end up with inaccurate file names in the header.

Does anyone working on this project need to know that this is yet another file in Nos? No, they do not. All of our files are part of Nos. Unless, of course, they’re part of NosTests. But this is more duplicate information that can be outdated.

Was this file created on June 3 or March 6? Based on the current year and/or the fact that Martin created it, we can make a pretty safe guess. Do we want to be guessing about dates? No, we do not.

Does the date format always start with the day followed by the month? Nope. It depends on the date preferences of the person who created it.

Is there another way to determine the date this file was created? Yes, indeed! Just check the git history!

## Considered Options

### Remove all file header comments
**Pros**:
- Inaccurate comments will be gone
- Inconsistent date format will be gone
- Unnecessary information will be gone

**Cons**:
- You’ll have to read the file name in Xcode or GitHub to know the file name
- You’ll have to find creation dates for files in git history

### Choose a date format and try harder in code reviews
We can decide on a date format such as ISO 8601 and use it exclusively. In code reviews, we can work harder to ensure these comments stay up to date whenever a file name changes.

**Pros**:
- Inaccurate comments will be (mostly) gone
- Inconsistent date format will be (mostly) gone

**Cons**:
- Some inaccurate comments will slip through code review
- Unnecessary information will remain
- We’ll need to update all existing comments for consistency

## Decision
We’ll remove all file header comments. We’ll do this incrementally by only removing header comments from the files we’re creating and updating in a PR. Eventually they’ll all be gone. If we get impatient, we can optionally we could create a PR that removes all remaining header comments.
