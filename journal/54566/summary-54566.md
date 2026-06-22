## Feature 54566: Make Hibernate Reactive / Panache work with @Transactional

Work ran from 2026-06-01 to 2026-06-22. PR quarkus#54683, merged by FroMage.

## Background

Stephane (FroMage) submitted PR quarkus#54566 to support jakarta.transaction.Transactional on reactive methods alongside the existing Panache annotations (@WithTransaction, @WithSession). His implementation created parallel session caching systems in SessionOperations and HibernateReactiveRecorder. The goal of this feature was to unify session creation so both paths share state, and migrate Panache tests from @WithTransaction to @Transactional.

## Key milestones

- Reverted Stephane's SessionOperations changes, kept his tests and deployment fix. Replaced Panache's internal SESSION_KEY_MAP/SESSION_FACTORY_MAP with delegation to HibernateReactiveRecorder.OPENED_SESSIONS_STATE.
- Discovered that eager session creation broke tests. Session creation must be deferred to Uni subscription time via Uni.createFrom().item(() -> ...) because the Vert.x connection is acquired lazily by HR.
- Split TestEndpoint into @Transactional and @WithTransaction variants to avoid shared DB state. FroMage then asked to simplify: migrate all to @Transactional, keep one @WithTransaction smoke test.
- Panache.currentTransaction() returned null under @Transactional because session.currentTransaction() did not detect transactions opened externally by TransactionalContextPool. Built VertxTransactionWrapper as a temporary bridge.
- DavideD fixed this in hibernate-reactive 3.4.2.Final (HR issue 2852). Bumped HR version and removed VertxTransactionWrapper.
- CI revealed testReactiveTransactional3 failure: test 201 (@Transactional) calls markForRollback on ExternalTransaction, but TransactionalInterceptorBase committed anyway. ExternalTransaction.markForRollback is informational by HR design — the external owner must check it.
- Added isMarkedForRollback(Context) to ReactiveResource interface, implemented in HibernateActionsStrategy. TransactionalInterceptorBase now checks before committing and rolls back if true.
- Stephane caught that isMarkedForRollback only checked stateful sessions. Added currentTransaction(T session) abstract method to OpenedSessionsState, implemented in both StatefulImpl and StatelessImpl. Wrote a failing test with stateless session first, then fixed.
- Wrote two HR tests in ExternalTransactionTest proving markForRollback on ExternalTransaction does not prevent commit — documenting the by-design behavior.
- ORM 7.4.1 introduced HHH90001002 double-stop warning on JCacheRegionFactory. Unrelated to this feature; excluded affected modules from test-hibernate.sh.
