# Feature vertx5 Summary

Work on Vert.x 5 migration support for Hibernate Reactive and Panache in Quarkus, spanning 2026-05-20 to 2026-06-25. Started to investigate transactional test failures on Julien Ponge's Vert.x 5 Panache migration branch and ended with all Hibernate Reactive tests passing on the Quarkus 4.0 merge.

## Milestones

- Created feature to investigate transactional test failures on jponge/vertx5/panache branch (quarkusio/quarkus#54285)
- Found root cause: Vert.x 5 split ContextInternal.putLocal() and ContextLocals.get() into separate storage, breaking the reactive transaction detection guard
- Fix: use ContextLocals.put()/get() consistently instead of ContextInternal.putLocal(), following pattern from Clement Escoffier
- Confirmed extension-level HR tests all passed, failures were isolated to Panache integration tests
- Investigated CI failures on Quarkus 4.0 merge PR (quarkusio/quarkus#55020) at Julien's request
- Identified merge conflict had dropped SessionOperations changes from PR #54683
- Ported SessionOperations.java to Vert.x 5 APIs, replacing Key/ContextualDataStorage/SESSION_FACTORY_MAP with OPENED_SESSIONS_STATE
- Reduced failures from 11 to 5, remaining 5 needed unreleased HR fix (hibernate/hibernate-reactive#3876)
- Asked Davide for new HR 4.5.x release on Zulip
- HR 4.5.0.Final landed on Maven Central, bumped version from CR1 to Final
- Sent patch to Clement via git send-email, then got push access to cescoffier/quarkus and pushed directly after rebase
- Discovered WithSessionOnDemandTest broke because Vert.x 5 removed flat Object-keyed context.getLocal(Object) API
- Removed separate SESSIONS_LOCAL ContextLocal and HibernateReactiveVertxServiceProvider entirely
- OpenedSessionsState now stores sessions directly via HR ContextualDataStorage with BaseKey(type, uuid)
- Verified CI: zero Hibernate Reactive failures on Quarkus 4.0 merge PR after all fixes applied
