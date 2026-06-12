## Feature 54535 - OpenRewrite test for Panache Next to Quarkus Data relocation

Work started 2026-06-11, completed 2026-06-12. Requested by Guillaume in quarkusio/quarkus-updates#476 review.

## Goal

Write a test for the ChangeDependency OpenRewrite recipe that renames quarkus-hibernate-panache-next to quarkus-data-hibernate in the 3.37.alpha1.yaml recipe file.

## Milestones

- Wrote CoreUpdate337Test.java following the CoreUpdate331Test pattern
- Initial approach used explicit dependency versions (3.36.0 before, 3.37.0.CR1 after) which failed because OpenRewrite resolves the renamed artifact at the old version (quarkus-data-hibernate:3.36.0 does not exist)
- Switched to BOM-managed dependency pattern (quarkus-bom in dependencyManagement, no explicit version on the dependency) which is how real Quarkus projects work
- Test passes: before has quarkus-bom 3.36.0 with quarkus-hibernate-panache-next, after has quarkus-bom 3.37.0.CR1 with quarkus-data-hibernate
- Dropped the -deployment artifact test since end users never depend on deployment modules directly

## Key lesson

When testing ChangeDependency recipes where the new artifact only exists at the target version, use BOM-managed dependencies to avoid OpenRewrite resolution failures on non-existent artifact+version combinations.
