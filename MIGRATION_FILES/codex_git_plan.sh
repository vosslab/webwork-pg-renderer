#!/usr/bin/env bash
set -euo pipefail

# Non-interactive git plan script (run by User)
# Defaults (override via env):
DO_PUSH=${DO_PUSH:-0}
PUSH_WORKFLOWS=${PUSH_WORKFLOWS:-0}
DO_CLEANUP=${DO_CLEANUP:-0}
OPENWEBWORK_REMOTE=${OPENWEBWORK_REMOTE:-openwebwork}
OPENWEBWORK_REMOTE_URL=${OPENWEBWORK_REMOTE_URL:-https://github.com/openwebwork/renderer.git}
BRANCH_NAME=${BRANCH_NAME:-"port-from-master-$(date +%Y%m%d)"}

# Sanity: must be in a git repo
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

# Prevent accidental workflow staging unless explicitly allowed
if [[ "$PUSH_WORKFLOWS" != "1" ]]; then
  git restore --staged -- .github/workflows 2>/dev/null || true
fi

# Refuse to run if staged changes exist
if ! git diff --cached --quiet; then
  echo "ERROR: Staged changes detected. Run: git reset"
  exit 1
fi

current_branch=$(git rev-parse --abbrev-ref HEAD || echo "HEAD")
current_head=$(git rev-parse --short HEAD)
echo "Current branch: $current_branch"
echo "HEAD: $current_head"

# Ensure remotes
if ! git remote | grep -qx "$OPENWEBWORK_REMOTE"; then
  git remote add "$OPENWEBWORK_REMOTE" "$OPENWEBWORK_REMOTE_URL"
fi
# Fetch remotes (non-fatal if origin missing)
git fetch "$OPENWEBWORK_REMOTE" --prune
if git remote | grep -qx origin; then
  git fetch origin --prune || true
fi

# Prefer existing integration branch; avoid creating a new one.
PREFERRED_BRANCH=${PREFERRED_BRANCH:-integrate-from-voss}
if [[ "$current_branch" == "master" || "$current_branch" == "main" || "$current_branch" == "HEAD" ]]; then
  if git show-ref --verify --quiet "refs/heads/$PREFERRED_BRANCH"; then
    git switch "$PREFERRED_BRANCH"
  else
    git switch -c "$PREFERRED_BRANCH" "$OPENWEBWORK_REMOTE/main"
  fi
fi

# Hard refusal on protected branches
current_branch=$(git rev-parse --abbrev-ref HEAD || echo "HEAD")
if [[ "$current_branch" == "master" || "$current_branch" == "main" || "$current_branch" == "HEAD" ]]; then
  echo "ERROR: Refusing to run on $current_branch."
  exit 1
fi

# --- Submodule conversion for lib/PG ---
# Determine expected gitlink from upstream
up_pg_commit=$(git ls-tree "$OPENWEBWORK_REMOTE/main" lib/PG | awk '{print $3}')

libpg_mode=$(git ls-tree HEAD lib/PG | awk '{print $1}')
if [[ "$libpg_mode" != "160000" ]]; then
  echo "ERROR: lib/PG is not a gitlink. Convert manually (back up first), then re-run."
  exit 1
fi

# Ensure .gitmodules has lib/PG block
if [[ ! -f .gitmodules ]]; then
  : > .gitmodules
fi
# Remove any existing lib/PG block
awk '
  BEGIN{inblock=0}
  /^\[submodule "lib\/PG"\]/{inblock=1; next}
  inblock && /^\[submodule /{inblock=0}
  !inblock{print}
' .gitmodules > .gitmodules.tmp
mv .gitmodules.tmp .gitmodules
# Append desired block
if ! grep -q '\[submodule "lib/PG"\]' .gitmodules; then
  printf '%s\n' "[submodule \"lib/PG\"]" >> .gitmodules
  printf '%s\n' "  path = lib/PG" >> .gitmodules
  printf '%s\n' "  url = https://github.com/openwebwork/pg.git" >> .gitmodules
  printf '%s\n' "  branch = main" >> .gitmodules
fi

# Set gitlink to upstream commit (no submodule checkout required)
if [[ -n "$up_pg_commit" ]]; then
  git update-index --add --cacheinfo 160000,"$up_pg_commit",lib/PG
else
  echo "WARNING: Could not find upstream gitlink for lib/PG; skipping gitlink update."
fi

# Commit submodule metadata if changed
git add .gitmodules lib/PG
if ! git diff --cached --quiet; then
  git commit -m "Set lib/PG as submodule"
fi

# --- Grouped commits (exclude workflows, then migration artifacts) ---
git add -A -- :!.github/workflows :!MIGRATION_FILES :!preserve
if ! git diff --cached --quiet; then
  git commit -m "Phase B/C core changes"
fi
git reset -q

git add -A MIGRATION_FILES preserve
if ! git diff --cached --quiet; then
  git commit -m "Migration artifacts"
fi
git reset -q

# --- Workflow gating ---
workflow_changes=0
if git status --porcelain | grep -q '^.. .github/workflows/'; then
  workflow_changes=1
fi
if [[ $workflow_changes -eq 1 ]]; then
  if [[ "$PUSH_WORKFLOWS" == "1" ]]; then
    git add -A -- .github/workflows
    if ! git diff --cached --quiet; then
      git commit -m "Workflow updates (optional)"
    fi
  else
    echo "WARNING: Workflow changes present but not committed (set PUSH_WORKFLOWS=1 to commit)."
  fi
fi

# --- Optional cleanup (disabled by default) ---
if [[ "$DO_CLEANUP" == "1" ]]; then
  echo "DO_CLEANUP=1: (placeholder) cleanup steps would run here."
fi

# --- Summary ---

echo "\n=== Summary ==="
git log --oneline --decorate --max-count=30

echo "\n=== Diff vs upstream (excluding lib) ==="
git diff --name-status "$OPENWEBWORK_REMOTE/main"..HEAD -- ':!lib/*'

echo "\n=== Status ==="
git status -sb

# --- Optional push ---
if [[ "$DO_PUSH" == "1" ]]; then
  if [[ $workflow_changes -eq 1 && "$PUSH_WORKFLOWS" != "1" ]]; then
    echo "Refusing to push: workflow changes exist but PUSH_WORKFLOWS=0."
    exit 1
  fi
  git push -u origin HEAD
fi
