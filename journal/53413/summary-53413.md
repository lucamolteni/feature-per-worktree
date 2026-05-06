# Feature 53413 Summary

Bug fix for import.sql not being executed when using only StatelessSession with no @Entity classes.

Work started 2026-04-02, completed 2026-04-30.

## Milestones

- Identified root cause: SchemaManagementToolCoordinator skips all schema actions when metadata.getContributors() is empty (no entities, tables, or sequences)
- Initial fix was a Quarkus-side workaround in PrevalidatedQuarkusMetadata.getContributors(), returning a synthetic contributor when the set is empty
- Moved the fix upstream into Hibernate ORM: SchemaManagementToolCoordinator.ActionGrouping.interpret defaults to a synthetic "orm" contributor when the set is empty
- Addressed code review from mbellade: moved the check from interpret(Set, Map) to interpret(Metadata, Map) for cleaner separation
- Created Hibernate ORM PRs for both 7.3 (PR #12138) and main/7.4 (PR #12139), Jira issue HHH-20321
- Reverted the Quarkus workaround and replaced it with a regression test only (ImportSqlLoadScriptNoEntitiesTestCase)
- Original Quarkus PR #53419 closed in favor of test-only draft PR #53591, gated on Hibernate ORM 7.3.2 release
- Quarkus upstream bumped to Hibernate ORM 7.3.2.Final on Apr 21, satisfying the merge condition
- PR #53591 approved by yrodiere on Apr 22, rebased and converted from draft to ready for merge
