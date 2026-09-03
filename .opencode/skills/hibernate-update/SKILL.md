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
- `main/hibernate-search/` must exist (for tag inspection when Search is bumped).

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

Also from `<feature>/quarkus/bom/application/pom.xml`:
- `elasticsearch-opensource-components.version`

And from `<feature>/quarkus/build-parent/pom.xml`:
- `elasticsearch-server.version`
- `opensearch-server.version`

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

### 2b. Align Elasticsearch and OpenSearch versions (when Search is bumped)

When updating `hibernate-search.version`, the Elasticsearch client and server image versions must also be aligned. Hibernate Search tests against specific ES and OpenSearch versions; Quarkus must match.

**Extract target versions from Hibernate Search:**
```bash
cd main/hibernate-search
git fetch upstream --tags
git show <search-tag>:build/parents/build/pom.xml | grep -E 'version.org.elasticsearch.client|version.org.elasticsearch.latest|version.org.opensearch.latest'
```

This yields three values:
- `version.org.elasticsearch.client` — the ES client library version (e.g., `9.4.1`)
- `version.org.elasticsearch.latest` — the ES server version tested against (e.g., `9.4.1`)
- `version.org.opensearch.latest` — the OpenSearch server version tested against (e.g., `3.6.0`)

**Update three properties in Quarkus:**

1. `elasticsearch-opensource-components.version` in `<feature>/quarkus/bom/application/pom.xml` — controls the ES REST client and Java client versions
2. `elasticsearch-server.version` in `<feature>/quarkus/build-parent/pom.xml` — controls the ES Docker image used in tests (also drives `logstash.image` and `kibana.image`)
3. `opensearch-server.version` in `<feature>/quarkus/build-parent/pom.xml` — controls the OpenSearch Docker image used in tests

**Update hardcoded elasticsearch.version in test files:**

Many test properties files and Java test files hardcode `elasticsearch.version=9.X` or `elasticsearch.version", "9.X"`. When bumping the ES major.minor version, search and update ALL of them:

```bash
# Properties files
grep -rn 'elasticsearch.version=<old-minor>' --include="*.properties" <feature>/quarkus/ | grep -v target/
# Java files
grep -rn 'elasticsearch.version.*<old-minor>' --include="*.java" <feature>/quarkus/ | grep -v target/
```

Locations that typically need updating:
- `extensions/hibernate-search-orm-elasticsearch/deployment/src/test/resources/` — application-devui*.properties, application-start-offline.properties
- `extensions/hibernate-search-standalone-elasticsearch/deployment/src/test/resources/` — same pattern
- `integration-tests/hibernate-search-orm-elasticsearch/src/test/java/.../devservices/` — DevServices*Test.java files
- `integration-tests/hibernate-search-standalone-elasticsearch/src/test/java/.../devservices/` — same pattern

Replace the old minor version with the new one (e.g., `9.3` → `9.4`). Files that use just the major version (e.g., `elasticsearch.version=9`) do NOT need updating.

**Verify on Maven Central that the client artifacts exist:**
```bash
curl -sk "https://repo1.maven.org/maven2/org/elasticsearch/client/elasticsearch-rest-client/maven-metadata.xml" | grep "<version>"
curl -sk "https://repo1.maven.org/maven2/co/elastic/clients/elasticsearch-java/maven-metadata.xml" | grep "<version>"
```

Both `elasticsearch-rest-client` and `elasticsearch-java` use the same `elasticsearch-opensource-components.version` property, so pick a version available for both.

### 2c. Register new ORM service providers for native mode (major version bumps)

When bumping to a new ORM major version (e.g., 7.3 → 7.4), check whether ORM or Search introduced new services discovered via `ServiceLoader` / `META-INF/services`. Quarkus disables GraalVM's `UseServiceLoaderFeature` and requires explicit registration.

**Check for new service files in ORM:**
```bash
cd main/hibernate-orm
git diff <old-tag>..<new-tag> -- '**/META-INF/services/*'
```

**Check for new service files in Search:**
```bash
cd main/hibernate-search
git diff <old-search-tag>..<new-search-tag> -- '**/META-INF/services/*'
```

If new service files were added, they must be registered in one of:
- `ClassNames.java` `SERVICE_PROVIDERS` list — for services loaded by ORM's `ClassLoaderService.loadJavaServices()` at runtime
- A `ServiceProviderBuildItem` in the relevant Quarkus extension processor

For example, Hibernate Search 8.4.0.Final added `META-INF/services/org.hibernate.engine.extension.spi.ExtensionIntegration` (via HSEARCH-5627), which required adding `org.hibernate.engine.extension.spi.ExtensionIntegration` to `ClassNames.SERVICE_PROVIDERS` in the Quarkus ORM extension. Without this, the service is not found in native mode and causes NPEs at runtime.

### 3. Update pom.xml

Set these properties in `<feature>/quarkus/pom.xml`:
- `hibernate-orm.version` → new ORM version
- `hibernate-reactive.version` → new Reactive version
- `hibernate-search.version` → new Search version
- `hibernate-tools.version` → new ORM version (same as ORM)
- `bytebuddy.version`, `antlr.version`, `geolatte.version`, `hibernate-models.version` → if changed (from step 2)
- `jakarta.persistence-api.version`, `jakarta.data-api.version` → if changed (from step 2)

If Search was bumped (from step 2b):
- `elasticsearch-opensource-components.version` in `<feature>/quarkus/bom/application/pom.xml`
- `elasticsearch-server.version` in `<feature>/quarkus/build-parent/pom.xml`
- `opensearch-server.version` in `<feature>/quarkus/build-parent/pom.xml`
- All hardcoded `elasticsearch.version` in test `.properties` and `.java` files

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

If Elasticsearch/OpenSearch versions were bumped (because Search was bumped), add rows:
```
| Elasticsearch client | <old> | <new> |
| Elasticsearch server image | <old> | <new> |
| OpenSearch server image | <old> | <new> |
```

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
