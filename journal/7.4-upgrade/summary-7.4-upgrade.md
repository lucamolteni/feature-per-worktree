## Feature 7.4-upgrade: Bump Hibernate ORM to 7.4, Reactive to 3.4, Search to 8.4

Work ran from 2026-05-11 to 2026-06-08. Bumped the full Hibernate stack in Quarkus from ORM 7.3/Reactive 3.3/Search 8.3 to ORM 7.4.0.Final/Reactive 3.4.0.Final/Search 8.4.0.Final. PR #54083 merged into quarkus main.

## Milestones

- Created feature directory and initial version bump to CR1 releases, aligned geolatte 1.10 to 1.11 per ORM platform BOM
- Registered ChangesetCoordinatorInitiator service for ORM 7.4 temporal entity support — without this, SessionFactory creation fails with UnknownServiceException
- Updated ClassNames with 14 new annotations (Temporal, Changelog, Audited families) and refactored composite generator records
- Initially bumped Reactive to 4.4.0.CR1, which targets Vert.x 5 — incompatible with Quarkus (still on Vert.x 4). Corrected to 3.4.0.CR1 (Vert.x 4 line)
- Bumped from CR1 to Final releases, no dependency changes between CR1 and Final
- Native test failures after Search 8.4.0.Final: HSEARCH-5627 switched to ORM Extension SPI discovered via ServiceLoader, which is disabled in native mode. Fixed by adding ExtensionIntegration to SERVICE_PROVIDERS in ClassNames.java
- Bumped Elasticsearch client to 9.4.1, server images to ES 9.4.1 and OpenSearch 3.6.0 to align with Search 8.4. Had to update 12 test files hardcoding elasticsearch.version=9.3
- CI failures were all infrastructure (quay.io outages, Kubernetes mock timeouts, container startup failures) — zero Hibernate-related failures across two full CI runs
- Squashed all commits into one clean commit for final PR
- Wrote migration guide covering 6 behavioral changes, 2 DDL changes, PostgreSQL minimum version bump from 13 to 14
- Yoann review feedback: remove new feature mentions from migration guide intro, restructure Dev Services section to match wiki style
- Created issue 54668 for testing temporal entity support in Quarkus (requested by Yoann)
- Extracted /migration-guide as a standalone skill and improved /hibernate-update skill with lessons from this upgrade
