---
name: add-repo-to-feature
description: Add a repository worktree to an existing feature directory
user_invocable: true
---

# Add Repo to Feature

Usage: `/add-repo-to-feature <repo> <feature-number>` (e.g., `/add-repo-to-feature hibernate-orm 3223`)

Adds a worktree of the specified repository to an existing feature directory.

## Supported repos

- `hibernate-orm`
- `hibernate-reactive`
- `hibernate-tools`
- `hibernate-models`
- `quarkus-website`
- `quarkus-updates`

## Prerequisites

- Feature directory `<number>/` must exist (run `/create-feature` first).
- The repo must be cloned in `main/` (run `/init-workspace` first).

## Steps

1. **Validate**: Check that `~/git/hibernate/<number>/` exists and `main/<repo>` exists. Fail with a clear message if not.

2. **Create worktree** from `main/<repo>`:
   ```
   cd ~/git/hibernate/main/<repo>
   git worktree add ~/git/hibernate/<number>/<repo> <number>
   ```
   If branch `<number>` doesn't exist, create it from `upstream/main`:
   ```
   git worktree add -b <number> ~/git/hibernate/<number>/<repo> upstream/main
   ```

3. **Set up build config** in the worktree:
   - **For Maven repos** (quarkus, hibernate-tools): Create or prepend to `~/git/hibernate/<number>/<repo>/.mvn/maven.config`:
     ```
     -Dmaven.repo.local=$HOME/git/hibernate/<number>/.m2
     ```
     If `.mvn/maven.config` already exists (from the repo), prepend the line.
   - **For Gradle repos** (hibernate-orm, hibernate-reactive, hibernate-models): No `.mvn/maven.config` needed. To publish SNAPSHOTs to the feature's `.m2`, use:
     ```
     ./gradlew publishToMavenLocal -Dmaven.repo.local=$HOME/git/hibernate/<number>/.m2 -x test
     ```
   - **For non-build repos** (quarkus-website, quarkus-updates): No build config needed — just create the worktree.

4. **Confirm**: Print the updated feature directory contents and remind the user about IntelliJ IDEA setup:

   - **For Gradle repos** (hibernate-orm, hibernate-reactive, hibernate-models): Settings → Build, Execution, Deployment → Build Tools → Gradle:
     - **Build and run using**: Gradle (Default) — keep this as Gradle, do NOT switch to IntelliJ IDEA.
     - **Run tests using**: IntelliJ IDEA — switch this from Gradle to IntelliJ IDEA. Without this, running a single test from IDEA will run all tests via Gradle instead of just the selected one.
