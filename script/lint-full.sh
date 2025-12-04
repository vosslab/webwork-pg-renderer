#!/usr/bin/env bash
set -euo pipefail

# This script assumes it is running inside the container where PG/WeBWorK
# env vars and layout are present.

export PG_ROOT=${PG_ROOT:-/usr/app/lib/PG}
export WEBWORK_ROOT=${WEBWORK_ROOT:-/usr/app/lib/WeBWorK}

if [ ! -d "$PG_ROOT" ] || [ ! -d "$WEBWORK_ROOT" ]; then
  echo "PG_ROOT=$PG_ROOT or WEBWORK_ROOT=$WEBWORK_ROOT missing; aborting full lint."
  exit 1
fi

# Some PG modules expect VERSION in ../; add a symlink if needed.
if [ -f "$PG_ROOT/VERSION" ] && [ ! -f "$PG_ROOT/../VERSION" ]; then
  ln -s "$PG_ROOT/VERSION" "$PG_ROOT/../VERSION" 2>/dev/null || true
fi

echo "Full Perl syntax check (WeBWorK/PG + app)..."
find lib -maxdepth 6 -type f -name '*.pm' -print0 | xargs -0 -n1 perl -c
