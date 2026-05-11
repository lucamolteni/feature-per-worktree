---
name: hibernate-update
description: Use when bumping Hibernate ORM, Reactive, Search, and Tools versions in a Quarkus feature branch — either from a dependabot PR URL or explicit version numbers
---

# Hibernate Update

Usage: `/hibernate-update <versions or PR URL>` in a feature directory context.

Examples:
- `/hibernate-update ORM 7.2.9.Final, Reactive 3.2.9.Final`
- `/hibernate-update ORM 7.4.0.CR1` (Reactive may not exist yet for major bumps)
- `/hibernate-update https://github.com/quarkusio/quarkus/pull/53334`

## Input Parsing

**From explicit versions:** Extract ORM and Reactive versions from free text. Tools version always equals ORM version. Search version may also be specified; if not, leave unchanged unless the user says otherwise.

**From PR URL:** Fetch with `gh pr view <number> --repo quarkusio/quarkus --json body,title,baseRefName` and parse the version table from the body to extract target versions.

## Prerequisites

- A feature directory must already exist with a Quarkus worktree and seeded `.m2`. If not, tell the user to run `/create-feature` first.
- `main/hibernate-orm/` must exist (for tag inspection). The feature does NOT need its own `hibernate-orm/` worktree — use `main/hibernate-orm` to read tags.

## Steps

### 1. Read current versions

Extract current values from `<feature>/quarkus/pom.xml`:
- `hibernate-orm.version`
- `hibernate-reactive.version`
- `hibernate-tools.version`
- `hibernate-search.version`
- `bytebuddy.version`
- `antlr.version`
- `hibernate-models.version`
- `geolatte.version`

These become the "From" column in the PR body.

### 2. Align ORM-controlled dependency versions

The Quarkus pom.xml tracks several properties that must stay aligned with what Hibernate ORM uses internally. These are marked with `<!-- version controlled by Hibernate ORM's needs -->`.

In `<feature>/hibernate-orm/`, fetch tags and read the target ORM version's `settings.gradle` to extract:
```bash
cd <feature>/hibernate-orm
git fetch upstream --tags
git show <new-orm-tag>:settings.gradle | grep -E 'def (antlrVersion|byteBuddyVersion|geolatteVersion|hibernateModelsVersion)'
```

The tag format varies:
- `.Final` versions: strip the `.Final` suffix (e.g., `7.2.9.Final` → tag `7.2.9`)

**Try `gradle/libs.versions.toml` first** (ORM 7.4+):
```bash
git show <tag>:gradle/libs.versions.toml | grep -E '^(antlr|byteBuddy|geolatte|hibernateModels|jpa|data) = '
```

**Fall back to `settings.gradle`** (ORM 7.3 and earlier):
```bash
git show <tag>:settings.gradle | grep -E 'def (antlrVersion|byteBuddyVersion|geolatteVersion|hibernateModelsVersion)'
```

Also check the **platform BOM** for JPA and Jakarta Data API versions:
```bash
curl -sk "https://repo1.maven.org/maven2/org/hibernate/orm/hibernate-platform/<version>/hibernate-platform-<version>.pom"
```

Compare extracted versions with current Quarkus pom.xml values and update any that differ:
- `antlr` → `antlr.version`
- `byteBuddy` → `bytebuddy.version`
- `geolatte` → `geolatte.version`
- `hibernateModels` → `hibernate-models.version`
- `jakarta.persistence-api` → `jakarta.persistence-api.version`
- `jakarta.data-api` → `jakarta.data-api.version`

### 3. Update pom.xml

Set these properties in `<feature>/quarkus/pom.xml`:
- `hibernate-orm.version` → new ORM version
- `hibernate-reactive.version` → new Reactive version
- `hibernate-search.version` → new Search version
- `hibernate-tools.version` → new ORM version (same as ORM)
- `bytebuddy.version`, `antlr.version`, `geolatte.version`, `hibernate-models.version` → if changed (from step 2)
- `jakarta.persistence-api.version`, `jakarta.data-api.version` → if changed (from step 2)

### 4. Build Quarkus

```bash
cd <feature>/quarkus
~/git/hibernate/scripts/build-fast.sh
```

Use `-B` flag and redirect output to a temp file to capture errors.

**If build fails:** STOP. Show the user the compilation errors. Let them fix the issues (e.g., API changes between versions). After they fix, re-run the build. Stage any files they changed alongside `pom.xml`.

### 5. Run Hibernate tests

```bash
~/git/hibernate/scripts/test-hibernate-update.sh <feature-name>
```

**If tests fail:** STOP. Show the user the test failures. Let them fix. After they fix, re-run the tests.

### 6. Commit

Stage `pom.xml` and any other files changed during fixes. Do NOT stage `.mvn/maven.config` (local repo path is a local-only change).

**Prefer separate commits** for logically independent changes:
1. Version bumps in `pom.xml` — explain what changed and why (e.g., which versions are aligned with ORM)
2. Each source code fix — explain what broke and why the fix is correct
3. Test/annotation updates — explain what changed in ORM that required the update

Each commit message should explain the **why**, not just the what.

### 7. Push

```bash
git push origin <branch-name>
```

If the branch was force-pushed before (amending), use `--force`.

### 8. Create or update PR

**If a PR already exists** for this branch (check with `gh pr list --head <branch>`): update title and body with `gh pr edit`.

**If no PR exists:** create one with `gh pr create` targeting the upstream branch.

**PR title format:**
```
[<base-branch>] Bump Hibernate ORM to <ORM>, Reactive to <Reactive>
```

**PR body format:**
```markdown
## Summary
Bumps the hibernate group with N updates:

| Package | From | To |
| --- | --- | --- |
| org.hibernate.orm:hibernate-core | <old> | <new> |
| org.hibernate.orm:hibernate-graalvm | <old> | <new> |
| org.hibernate.orm:hibernate-envers | <old> | <new> |
| org.hibernate.orm:hibernate-spatial | <old> | <new> |
| org.hibernate.orm:hibernate-processor | <old> | <new> |
| org.hibernate.orm:hibernate-jpamodelgen | <old> | <new> |
| org.hibernate.orm:hibernate-community-dialects | <old> | <new> |
| org.hibernate.orm:hibernate-vector | <old> | <new> |
| org.hibernate.reactive:hibernate-reactive-core | <old-reactive> | <new-reactive> |
| org.hibernate.tool:hibernate-tools-language | <old-tools> | <new-tools> |
| org.hibernate.search:hibernate-search | <old-search> | <new-search> |

<any additional notes about fixes applied, e.g. service registrations, annotation updates>

## Test plan
- [x] Hibernate ORM/Reactive extensions and integration tests pass locally
```

If any ORM-controlled dependencies were also updated (bytebuddy, antlr, geolatte, etc.), add them as additional rows in the table.

If Reactive was not updated, note why in the summary (e.g., "Hibernate Reactive left at X — no compatible release for ORM Y yet").

## Handling Compilation Failures

When the build fails due to API changes between Hibernate versions:

1. Check out the appropriate tag in `main/hibernate-orm` to investigate the API change:
   ```bash
   git show <tag>:<path-to-changed-file>
   ```
2. Show the user the error and the relevant API diff.
3. Let the user fix the Quarkus code.
4. After the fix, re-run build and tests.
5. Include a note about the fix in the PR body.

## Step 10. Generate Migration Guide

After the PR is created, run `/migration-guide` to generate the Quarkus wiki migration guide entry for this version bump.
