## Feature 51205 - Per-PU blocking/reactive bootstrap control

Work ran from 2026-07-15 to 2026-07-30. Reviewed and guided an external contributor (simrank0) through PR 55382, which adds per-persistence-unit jdbc.enabled and reactive.enabled config properties to Hibernate ORM in Quarkus.

## Milestones

- Reviewed initial PR approach: contributor combined explicit config check and datasource-inference into a single orElse expression. Suggested splitting into two separate if blocks for clarity.
- Improved log messages to reference the actual config property name so users can trace why a PU was skipped.
- Added DEBUG logging in tests to verify interpolated messages appear correctly.
- Discussed Stephane's review comment about the global blocking flag. Clarified that quarkus.hibernate-orm.blocking already serves as the global equivalent; only a global reactive flag is missing (follow-up work).
- Guillaume flagged @WithParentName as problematic with YAML config when sibling properties exist. Contributor addressed by changing from bare jdbc/reactive to jdbc.enabled/reactive.enabled.
- Contributor force-pushed with fixes adopting the split-if pattern on both blocking and reactive sides.
- Verified tests pass locally after building with -Dquickly.
- PR merged 2026-07-30 after Guillaume's approval.
