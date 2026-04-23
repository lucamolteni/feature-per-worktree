#!/bin/bash
set -e

# Build all hibernate-related modules without tests, then run verification tests
# Usage: test-hibernate-update.sh <feature-dir>
# Example: test-hibernate-update.sh 3.33-branch-hibernate-update

if [ -z "$1" ]; then
    echo "Usage: $0 <feature-dir>"
    echo "Example: $0 3.33-branch-hibernate-update"
    exit 1
fi

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$1" = "." ]; then
    RESOLVED_DIR="$(pwd)"
    # If the current directory is itself a Quarkus checkout, use it directly
    if [ -f "$RESOLVED_DIR/extensions/hibernate-orm/pom.xml" ]; then
        QUARKUS_DIR="$RESOLVED_DIR"
    else
        # Walk up to find the feature root (parent of quarkus/)
        FEATURE_DIR="$RESOLVED_DIR"
        while [ "$FEATURE_DIR" != "$WORKSPACE_ROOT" ] && [ "$FEATURE_DIR" != "/" ]; do
            if [ -d "$FEATURE_DIR/quarkus" ]; then
                break
            fi
            FEATURE_DIR="$(dirname "$FEATURE_DIR")"
        done
        QUARKUS_DIR="$FEATURE_DIR/quarkus"
    fi
else
    FEATURE_DIR="$WORKSPACE_ROOT/$1"
    QUARKUS_DIR="$FEATURE_DIR/quarkus"
fi

if [ ! -d "$QUARKUS_DIR" ]; then
    echo "ERROR: $QUARKUS_DIR does not exist"
    exit 1
fi

cd "$QUARKUS_DIR"

# JPA DB-specific tests limited to PostgreSQL and H2; other DBs (Oracle, DB2, MySQL,
# MariaDB, MSSQL) rely on CI — Docker images are unreliable on Mac ARM
echo ">>> Building hibernate-related modules (skip tests) in $QUARKUS_DIR ..."
mvnd -pl extensions/hibernate-orm/runtime,\
extensions/hibernate-orm/deployment,\
extensions/hibernate-reactive/runtime,\
extensions/hibernate-reactive/deployment,\
extensions/panache/hibernate-reactive-panache-common/runtime,\
extensions/panache/hibernate-reactive-panache-common/deployment,\
extensions/panache/hibernate-reactive-panache/runtime,\
extensions/panache/hibernate-reactive-panache/deployment,\
extensions/spring-data-jpa/runtime,\
extensions/spring-data-jpa/deployment,\
integration-tests/jpa,\
integration-tests/jpa-h2,\
integration-tests/jpa-h2-embedded,\
integration-tests/jpa-postgresql,\
integration-tests/jpa-postgresql-withxml,\
integration-tests/jpa-mapping-xml,\
integration-tests/jpa-without-entity,\
integration-tests/hibernate-orm-data,\
integration-tests/hibernate-orm-tenancy/schema,\
integration-tests/hibernate-orm-tenancy/discriminator,\
integration-tests/hibernate-reactive-postgresql,\
integration-tests/hibernate-reactive-panache,\
integration-tests/smallrye-context-propagation,\
integration-tests/devtools \
install -DskipTests

echo ">>> Running verification tests..."
mvnd --serial -pl extensions/hibernate-orm/deployment,\
extensions/hibernate-reactive/deployment,\
extensions/panache/hibernate-reactive-panache-common/deployment,\
extensions/panache/hibernate-reactive-panache/deployment,\
extensions/spring-data-jpa/deployment,\
integration-tests/jpa,\
integration-tests/jpa-h2,\
integration-tests/jpa-h2-embedded,\
integration-tests/jpa-postgresql,\
integration-tests/jpa-postgresql-withxml,\
integration-tests/jpa-mapping-xml,\
integration-tests/jpa-without-entity,\
integration-tests/hibernate-orm-data,\
integration-tests/hibernate-orm-tenancy/schema,\
integration-tests/hibernate-orm-tenancy/discriminator,\
integration-tests/hibernate-reactive-postgresql,\
integration-tests/hibernate-reactive-panache,\
integration-tests/smallrye-context-propagation,\
integration-tests/devtools \
verify -Dtest-containers=true
