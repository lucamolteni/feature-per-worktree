#!/usr/bin/env bash
set -euo pipefail
exec mvnd -e -DskipDocs -DskipTests -DskipITs -Dinvoker.skip -DskipExtensionValidation -Dskip.gradle.tests -Dtruststore.skip clean install "$@"
