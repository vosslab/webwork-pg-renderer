#!/usr/bin/env bash
set -euo pipefail

# Make sure in-repo libs and vendored deps are on the path for syntax checks.
# Include vendor-installed modules under ./local if present.
export PERL5LIB="lib:lib/WeBWorK/lib:lib/PG:local/lib/perl5:${PERL5LIB:-}"

# Ensure deps from cpanfile are installed locally if cpanm is available.
if command -v cpanm >/dev/null 2>&1; then
  echo "Ensuring CPAN deps (cpanfile) are installed locally..."
  PERL_CPANM_HOME=${PERL_CPANM_HOME:-$PWD/.cpanm}
  PERL_CPANM_OPT=${PERL_CPANM_OPT:--L local}
  cpanm --installdeps . >/dev/null || true
else
  echo "cpanm not found; skipping cpanfile deps. Install cpanm for host-side lint, or run lint inside the container."
fi

if ! perl -e 'use Future::AsyncAwait 0.52;' >/dev/null 2>&1; then
  echo "Future::AsyncAwait 0.52+ is not available on this host even after cpanm."
  echo "Install it (e.g., 'cpanm Future::AsyncAwait' or apt/brew package),"
  echo "or run lint inside the container: podman exec pg-test ./script/lint.sh"
  exit 1
fi

echo "Perl syntax check (all modules)..."
find lib -name '*.pm' -print0 | xargs -0 -n1 perl -c

echo "Perl syntax check (scripts)..."
perl -c script/render_app script/smoke.pl

if command -v shellcheck >/dev/null 2>&1; then
  echo "Shellcheck (run.sh, smoke.sh)..."
  shellcheck run.sh script/smoke.sh || true
else
  echo "Shellcheck not installed; skipping shell lint. Install via 'brew install shellcheck'."
fi

echo "Done."
