# 4. Protect main branch

Date: 2024-01-18

Authors: Josh Brown

## Status

Accepted

## Context & Problem Statement

Without branch protections, it’s too easy to merge PRs to the `main` branch without running checks or getting the necessary approvals. 

## Considered Options

### Leave the `main` branch unprotected

**Pros**:

- It's easy. Leaving the main branch unprotected requires zero effort.

**Cons**:

- PRs can be merged easily without approval.
- PRs can be merged easily without passing checks.
- It's easy to push directly to `main` without creating a PR and getting approval(s) and PR checks.

### Protect the `main` branch

To do this, we propose adding the following branch protection rules [in GitHub](https://github.com/planetary-social/nos/settings/rules):

- Restrict deletions. Only allow users with bypass permissions to delete matching refs.
- Require a pull request before merging. Require all commits be made to a non-target branch and submitted via a pull request before they can be merged.
- Required approvals: 1. The number of approving reviews that are required before a pull request can be merged.
- Require status checks to pass:
	- Unit tests
	- swift_lint
	- Check CHANGELOG
	- license/cla
- Block force pushes. Prevent users with push access from force pushing to refs.

We’d use the Rulesets feature rather than the Branch protection rules for the benefits [outlined by GitHub](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets#about-rulesets-protected-branches-and-protected-tags). Specifically: “Anyone with read access to a repository can view the active rulesets for the repository. This means a developer can understand why they have hit a rule, or an auditor can check the security constraints for the repository, without requiring admin access to the repository.”

**Pros**:

Protecting the main branch promotes the behavior we want by making it harder to do the wrong things: 

- It’s harder to bypass PR checks we’ve determined are required to merge.
- It’s harder to merge PRs without the required approval.

**Cons**:

The pros are also cons, at least in the event of an emergency:

- It’s harder to bypass PR checks.
- It’s harder to merge PRs without the required approval.

Note that it’s only *slightly harder* -- not impossible -- to bypass PR checks and the required approval. There’s always a manual override that admins and maintainers can use.

## Decision

We’ve agreed to protect the `main` branch using Rulesets, as this encourages us to pass the checks and get the required PR approval. We’ll allow admins and maintainers to bypass checks and approvals, which requires an extra step when merging a PR.
