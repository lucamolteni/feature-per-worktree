# Feature 54577

Fix for duplicate feature name conflict when quarkus-data-hibernate (Panache Next) and quarkus-hibernate-orm-panache coexist in the same project. Work completed on 2026-06-01.

## Milestones

- Investigated root cause: both extensions registered FeatureBuildItem with the same name hibernate-orm-panache
- The quarkus-data-hibernate processor had a FIXME comment acknowledging the wrong feature name
- Reproduced on both 3.36.0 and main (999-SNAPSHOT) using quarkus create app with both extensions
- Added QUARKUS_DATA_HIBERNATE to the Feature enum in core/deployment
- Updated PanacheHibernateResourceProcessor to use the new feature constant
- Verified reproducer builds successfully after fix
- PR for main: https://github.com/quarkusio/quarkus/pull/54586
- Backported to 3.36 branch, adapting for the old extension name (hibernate-panache-next instead of quarkus-data-hibernate)
- Used HIBERNATE_PANACHE_NEXT feature constant on the 3.36 branch
- Built and verified the backport with 3.36.999-SNAPSHOT
- PR for 3.36: https://github.com/quarkusio/quarkus/pull/54587
