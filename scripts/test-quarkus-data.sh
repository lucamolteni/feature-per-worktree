#!/bin/bash
set -e

# Build and test Quarkus Data JPA (formerly Panache Next)
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

if [ -d "extensions/quarkus-data/quarkus-data-jpa" ]; then
    DATA_JPA_DIR="extensions/quarkus-data/quarkus-data-jpa"
elif [ -d "extensions/panache/hibernate-panache-next" ]; then
    DATA_JPA_DIR="extensions/panache/hibernate-panache-next"
else
    echo "ERROR: Neither quarkus-data-jpa nor hibernate-panache-next found"
    exit 1
fi

echo ">>> Building Quarkus Data JPA ($DATA_JPA_DIR) ..."
mvnd -f "$DATA_JPA_DIR" install -DskipTests

echo ">>> Running tests ($DATA_JPA_DIR) ..."
mvnd --serial -f "$DATA_JPA_DIR" verify -Dtest-containers=true
