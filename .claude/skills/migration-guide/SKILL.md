---
name: migration-guide
description: Generate a Quarkus migration guide entry for a Hibernate version upgrade, in asciidoc format ready for the Quarkus wiki
---

# Migration Guide Generator

Usage: `/migration-guide` — run from within a feature directory that has a Hibernate version bump committed.

Generates a Quarkus migration guide entry in asciidoc format, ready to be copied to the Quarkus wiki.

## Instructions

1. Clone the Quarkus wiki repo into the feature directory and read earlier migration guide files to match style:
   ```bash
   git clone --depth 1 https://github.com/quarkusio/quarkus.wiki.git ~/git/hibernate/<feature>/quarkus-wiki
   ```
   Read files like `Migration-Guide-3.26.asciidoc` for style reference. This is much faster than web searches.

2. Read the commits that bump the Hibernate versions to identify the old and new versions of:
   - Hibernate ORM
   - Hibernate Reactive
   - Hibernate Search

3. For **Hibernate ORM**, fetch the migration guide from `https://docs.hibernate.org/orm/<NEW_VERSION>/migration-guide/` and extract:
   - API changes (removed/deprecated annotations, classes, methods)
   - SPI changes (if relevant to applications)
   - Behavioral changes (changed semantics, stricter validation, spec compliance)
   - DDL changes (schema generation differences)
   - Keep it concise — synthesize, don't copy verbatim. Link back to upstream guide sections.
   - Use the **exact HTML anchors** from the upstream guide (inspect the page). Anchors for named sections use the format `#section-id`, while auto-generated ones use `#_underscored_title`.

4. For **minimum database versions**, compare the dialect pages between old and new ORM versions:
   - Old: `https://docs.hibernate.org/orm/<OLD_VERSION>/dialect/dialect.html`
   - New: `https://docs.hibernate.org/orm/<NEW_VERSION>/dialect/dialect.html`
   - Only list databases where the minimum version actually changed.

5. For **Hibernate Reactive**, write a short section noting it was upgraded and that breaking changes are inherited from Hibernate ORM (listed above). If Reactive was not upgraded, note that.

6. For **Hibernate Search**, fetch the migration guide from `https://docs.hibernate.org/search/<NEW_VERSION>/migration/html_single/` and summarize. If fully backwards-compatible, say so briefly.

7. Check for **Elasticsearch/OpenSearch Dev Services version bumps** by looking at recent commits on the branch for changes to `elasticsearch-server.version`, `opensearch-server.version`, and `elasticsearch-opensource-components.version` in `build-parent/pom.xml` and `bom/application/pom.xml`. If any changed, add a section noting the old and new default versions.

8. Write the output to `migration-guide.asciidoc` in the feature's quarkus worktree root.

## Output Format

Follow the style of the raw asciidoc in the wiki repo. The heading structure uses `==` for top-level component groupings and `===` for subsections:

```asciidoc
== Hibernate ORM

=== Upgrade to Hibernate ORM <version>

The Quarkus extension for Hibernate ORM was upgraded to Hibernate ORM <version>.

Hibernate ORM <version> is for the most part backwards-compatible with Hibernate ORM <previous>. However, a few breaking changes are to be expected. Below are the ones most likely to affect existing applications.

Refer to the https://docs.hibernate.org/orm/<version>/migration-guide/[Hibernate ORM <version> migration guide] for more information.

=== API changes

* https://docs.hibernate.org/orm/<version>/migration-guide/#anchor[Description of change].

=== Behavioral changes

* https://docs.hibernate.org/orm/<version>/migration-guide/#anchor[Description of change].

=== DDL changes

* https://docs.hibernate.org/orm/<version>/migration-guide/#anchor[Description of change].

=== Minimum database versions

* DatabaseName: bumped minimum version from X to Y

See https://docs.hibernate.org/orm/<version>/dialect/dialect.html[here] for details on the current minimum versions.

== Hibernate Reactive

=== Upgrade to Hibernate Reactive <version>

The Quarkus extension for Hibernate Reactive was upgraded to Hibernate Reactive <version>.

Hibernate Reactive <version> is backwards-compatible with Hibernate Reactive <previous>, with the exception of a few breaking changes inherited from Hibernate ORM and listed above.

== Hibernate Search

=== Upgrade to Hibernate Search <version>

The Quarkus extensions for Hibernate Search were upgraded to Hibernate Search <version>.

<Compatibility summary>.

Refer to the https://docs.hibernate.org/search/<version>/migration/html_single/[Hibernate Search <version> migration guide] for more information.

== Elasticsearch and OpenSearch Dev Services

The Elasticsearch Dev Services now default to starting Elasticsearch <new>, instead of <old> previously.

The OpenSearch Dev Services now default to starting OpenSearch <new>, instead of <old> previously.

The Elasticsearch Java client was also upgraded from <old> to <new>.
```

## Key Rules

- This is a **synthesis**, not a copy of the upstream guide. Be concise.
- Use asciidoc link syntax: `https://url[link text]`
- Every bullet point should link to the relevant upstream migration guide section with the correct anchor.
- Omit subsections that have no changes (e.g., skip "DDL changes" if there are none).
- If minimum database versions haven't changed, either omit the section or note "No changes compared to previous version."
