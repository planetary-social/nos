# 1. Record architecture decisions

Date: 2024-01-16

Authors: Matt Lorentz

## Status

Accepted

## Context

We need to record the architectural decisions made on this project. Recording them will help us communicate to the team when architecture is changing and why, and it helps us re-evaluate past decisions when we want to change them.

## Decision

We will use Architecture Decision Records, as [described by Michael Nygard](http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions) to document "'architecturally significant' decisions: those that affect the structure, non-functional characteristics, dependencies, interfaces, or construction techniques."

We will store our Architecture Decision Records in our git repository, and use our existing pull request review process to evaluate changes.

We will use the [adr-tools](https://github.com/npryce/adr-tools) command line tool to help us create and link ADRs.

We have set up a template that adr-tools will use for new ADRs based on our [Notion Doc on ADRs](https://www.notion.so/nossocial/ADR-Template-36a2de963dcf43d1a057f5c3c6b1fab5?pvs=4).

## Consequences

See Michael Nygard's article, linked above. 
