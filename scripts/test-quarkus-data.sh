#!/bin/bash
set -e

# Build and test Quarkus Data Hibernate (formerly Panache Next)
# Auto-detects whether the extension has been renamed
# Usage: test-quarkus-data.sh <feature-dir>
# Example: test-quarkus-data.sh 39

if [ -z "$1" ]; then
    echo "Usage: $0 <feature-dir>"
    echo "Example: $0 39"
    exit 1
fi

WORKSPACE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$1" = "." ]; then
    RESOLVED_DIR="$(pwd)"
    if [ -f "$RESOLVED_DIR/extensions/hibernate-orm/pom.xml" ]; then
        QUARKUS_DIR="$RESOLVED_DIR"
    else
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

if [ -d "extensions/quarkus-data/quarkus-data-hibernate" ]; then
    DATA_DIR="extensions/quarkus-data/quarkus-data-hibernate"
elif [ -d "extensions/quarkus-data/quarkus-data-jpa" ]; then
    DATA_DIR="extensions/quarkus-data/quarkus-data-jpa"
elif [ -d "extensions/panache/hibernate-panache-next" ]; then
    DATA_DIR="extensions/panache/hibernate-panache-next"
else
    echo "ERROR: No quarkus-data-hibernate, quarkus-data-jpa, or hibernate-panache-next found"
    exit 1
fi

echo ">>> Building Quarkus Data Hibernate ($DATA_DIR) ..."
mvnd -f "$DATA_DIR" install -DskipTests

echo ">>> Running tests ($DATA_DIR) ..."
mvnd --serial -f "$DATA_DIR" verify -Dtest-containers=true

if [ -d "integration-tests/quarkus-data-hibernate" ]; then
    IT_DIR="integration-tests/quarkus-data-hibernate"
elif [ -d "integration-tests/quarkus-data-jpa" ]; then
    IT_DIR="integration-tests/quarkus-data-jpa"
elif [ -d "integration-tests/hibernate-panache-next" ]; then
    IT_DIR="integration-tests/hibernate-panache-next"
else
    echo "WARN: No integration test directory found, skipping integration tests"
    exit 0
fi

echo ">>> Running integration tests ($IT_DIR) ..."
mvnd --serial -f "$IT_DIR" verify -Dtest-containers=true
