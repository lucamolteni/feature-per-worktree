#!/usr/bin/env bash
set -euo pipefail
exec mvnd process-sources -Denforcer.skip -Dprotoc.skip "$@"
