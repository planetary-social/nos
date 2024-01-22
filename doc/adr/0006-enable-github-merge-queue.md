# 6. Enable GitHub merge queue

Date: 2024-01-19

Authors: Josh Brown


## Status

Proposed

## Context & Problem Statement

After all PR requirements are met, the author needs to click the merge button to merge their PR. Given that we often experience merge conflicts in the CHANGELOG, this means that when multiple PRs are ready to merge, the first person to look at their PR and click the merge button wins the race. Authors of other open PRs now need to manually resolve merge conflicts, wait for checks to pass, then manually merge their PR.

In summary: to get a PR merged, the author must look at the status, wait for checks, and click the merge button.

## Considered Options

### Enable GitHub merge queue

[GitHub merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue) can automatically merge pull requests once all requirements are met, including approvals and status checks. The author only needs to add their pull request to the merge queue, and GitHub will handle the rest.

**Pros**:

- PR authors can add their PR to the merge queue any time after creating the PR, and avoid needing to look at the status to see if it’s ready to merge. No more babysitting PRs!
- When a PR author adds their PR to the merge queue, they signal their intent to merge the PR to the rest of the team. If that PR fails to merge, perhaps due to conflicts, another developer may choose to resolve the conflicts and add the PR to the merge queue again without fear that the author wasn’t ready to merge their PR. This eliminates the need for the question: “Is this PR ready to merge, or are you planning to make other changes first?”
- In my experience, the merge queue has helped to speed up the process of merging to `main` in a fair way. Once a developer has a PR ready to go, they can add the PR to the merge queue without waiting around for checks to pass.

**Cons**:

- The team has slightly less control over when PRs are merged, as GitHub handles it.
- Due to our high frequency of merge conflicts in the CHANGELOG, merge queue may not benefit us much at all.

## Decision

If accepted, we’ll enable GitHub merge queue.
