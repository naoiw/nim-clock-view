#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p dist
nim js -d:release --out:dist/clock.js src/clock.nim
cp src/styles.css dist/styles.css
