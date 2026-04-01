#!/usr/bin/env bash
set -euo pipefail
exec mvnd -e -DskipTests -DskipITs -Dinvoker.skip -DskipExtensionValidation -Dskip.gradle.tests -Dtruststore.skip -Dno-test-modules -Dasciidoctor.fail-if=DEBUG clean install "$@"
