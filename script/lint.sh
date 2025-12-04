#!/usr/bin/env bash
set -euo pipefail

# Make sure in-repo libs and vendored deps are on the path for syntax checks.
# Include vendor-installed modules under ./local if present.
export PERL5LIB="lib:lib/WeBWorK:lib/WeBWorK/lib:lib/PG:lib/PG/lib:local/lib/perl5:${PERL5LIB:-}"

# Ensure deps from cpanfile are installed locally if cpanm is available.
if command -v cpanm >/dev/null 2>&1; then
  echo "Ensuring CPAN deps (cpanfile) are installed locally..."
  export PERL_CPANM_HOME="${PERL_CPANM_HOME:-"$(pwd)/.cpanm"}"
  export PERL_CPANM_OPT=${PERL_CPANM_OPT:--L local}
  mkdir -p "$PERL_CPANM_HOME/work"
  export PERL_CPANM_WORK=${PERL_CPANM_WORK:-$PERL_CPANM_HOME/work}
cpanm --installdeps --auto-cleanup --quiet . || true
else
  echo "cpanm not found; skipping cpanfile deps. Install cpanm for host-side lint, or run lint inside the container."
fi

if ! perl -e 'use Future::AsyncAwait 0.52;' >/dev/null 2>&1; then
  echo "Future::AsyncAwait 0.52+ is not available on this host even after cpanm."
  echo "Install it (e.g., 'cpanm Future::AsyncAwait' or apt/brew package),"
  echo "or run lint inside the container: podman exec pg-test ./script/lint.sh"
  exit 1
fi

echo "Perl syntax check (RenderApp core + safe controllers/models + TikZ shim)..."
# Core app module
perl -c lib/RenderApp.pm
# Controllers that do not require full PG/WeBWorK env
perl -c lib/RenderApp/Controller/Render.pm
perl -c lib/RenderApp/Controller/IO.pm
perl -c lib/RenderApp/Controller/Pages.pm
# Models: skip Problem.pm here (requires full PG stack)
if ls lib/RenderApp/Model/*.pm >/dev/null 2>&1; then
  for pm in lib/RenderApp/Model/*.pm; do
    case "$pm" in
      *Problem.pm) ;;
      *) perl -c "$pm" ;;
    esac
  done
fi
# TikZ shim
perl -c lib/PG/TikZImage.pm

echo
echo "Skipping full WeBWorK/PG-dependent modules (FormatRenderedProblem, RenderProblem, Model::Problem, etc) on host."
echo "For full-stack lint, run inside the container: podman exec pg-test ./script/lint-full.sh || true"

echo "Perl syntax check (scripts)..."
perl -c script/render_app script/smoke.pl

if command -v shellcheck >/dev/null 2>&1; then
  echo "Shellcheck (run.sh, smoke.sh)..."
  shellcheck run.sh script/smoke.sh || true
else
  echo "Shellcheck not installed; skipping shell lint. Install via 'brew install shellcheck'."
fi

echo "Done."
