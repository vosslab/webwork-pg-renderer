#!/usr/bin/env bash
set -euo pipefail

BASE_URL=${BASE_URL:-http://localhost:3000}
PG_PATH=${PG_PATH:-private/myproblem.pg}
CURL_BIN=${CURL_BIN:-curl}

# Split CURL_FLAGS once into an array (safe even if caller sets it).
if [[ -n "${CURL_FLAGS:-}" ]]; then
  # shellcheck disable=SC2206
  CURL_FLAGS=($CURL_FLAGS)
else
  CURL_FLAGS=(-fsS)
fi

BASE_URL=${BASE_URL%/}

run_curl() {
  local url=$1
  shift
  "${CURL_BIN}" "${CURL_FLAGS[@]}" --http1.1 "$url" "$@"
}

echo "Health check: ${BASE_URL}/health"
run_curl "${BASE_URL}/health" >/dev/null

echo "Render check (problemSeed=1234, outputFormat=classic): ${PG_PATH}"
run_curl "${BASE_URL}/render-api" \
  -H 'Content-Type: application/json' \
  -d "{\"sourceFilePath\":\"${PG_PATH}\",\"problemSeed\":1234,\"outputFormat\":\"classic\"}" \
  >/dev/null

echo "Smoke checks passed."
