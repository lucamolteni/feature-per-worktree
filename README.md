# feature-per-worktree

Orchestrate multi-repo feature branches with isolated git worktrees and dependency isolation for Java projects using Maven and Gradle.

Built for [Quarkus](https://quarkus.io/) and [Hibernate](https://hibernate.org/) development, where a single feature often spans multiple repositories with interdependent SNAPSHOT artifacts.

## Problem

When working across multiple Java repositories (e.g., Quarkus and its Hibernate dependencies), feature branches pollute each other's build artifacts. You change a dependency, rebuild, and suddenly your "clean" main branch has stale SNAPSHOTs in your local Maven repository. A/B comparison between upstream and your feature becomes unreliable.

## Solution

Each feature gets its own directory with:
- **Git worktrees** for every repo involved (not full clones — lightweight and instant)
- **An isolated `.m2` local Maven repository**, seeded from `main/.m2` via hardlinks (instant, near-zero disk overhead)
- **Maven config** that ensures builds never touch `~/.m2`

A `main/` directory always tracks upstream and has pre-built SNAPSHOTs ready for comparison.

## Directory Structure

```
~/git/hibernate/
├── main/                        # "real" clones, always at upstream/main
│   ├── quarkus/
│   ├── hibernate-orm/
│   ├── hibernate-reactive/
│   └── .m2/                     # pre-built SNAPSHOTs, always fresh
├── 3223/                        # feature QUARKUS-3223
│   ├── quarkus/                 # worktree from main/quarkus
│   ├── hibernate-orm/           # worktree, added on demand
│   └── .m2/                     # seeded from main/.m2 via hardlinks
├── 4567/                        # another feature
│   └── ...
```

## How It Works

### Dependency Isolation via Hardlinked `.m2`

When a feature directory is created, its `.m2` is seeded from `main/.m2` using `rsync --link-dest`. This creates hardlinks — the copy is instant and uses near-zero extra disk space. When you rebuild a SNAPSHOT in your feature, only the changed jars diverge and consume real space.

Every worktree has a `.mvn/maven.config` with `-Dmaven.repo.local` pointing to its feature's `.m2`, so Maven never touches `~/.m2`.

### A/B Comparison

1. Open `main/quarkus` — pre-built upstream SNAPSHOTs, always clean
2. Open `3223/quarkus` — your feature branch with its own SNAPSHOTs
3. Both are independently buildable and testable, no interference

### Refresh Loop

A background script (`scripts/refresh-main.sh`) keeps `main/` in sync: fetch upstream, reset all repos, rebuild SNAPSHOTs, sleep 1 hour, repeat.

## Prerequisites

- Java (JDK 17+)
- Maven and Gradle
- Git
- `$GITHUB_USERNAME` environment variable set to your GitHub username (for fork URLs)
- Forks of the upstream repositories under your GitHub account

## Usage with Claude Code

This repo is designed to be used with [Claude Code](https://claude.ai/code). The `.claude/skills/` directory contains skills that automate the workflow:

| Skill                                  | Description                                              |
|----------------------------------------|----------------------------------------------------------|
| `/init-workspace`                      | Clone all repos into `main/`, set up remotes, do builds  |
| `/create-feature <name>`               | Create a feature directory with worktree and isolated `.m2` |
| `/add-repo-to-feature <repo> <number>` | Add another repo's worktree to a feature                 |
| `/delete-feature <number>`             | Clean up worktrees and delete a feature directory        |
| `/refresh-main`                        | Start the hourly upstream refresh loop                   |

## Adapting to Your Projects

This workspace is currently configured for Quarkus/Hibernate development, but the pattern works for any multi-repo setup:

1. Fork the upstream repos to your GitHub account
2. Set `$GITHUB_USERNAME` to your GitHub username
3. Update `CLAUDE.md` with your repos and upstream URLs
4. Update the skills to reference your repos
5. Run `/init-workspace` to set everything up
