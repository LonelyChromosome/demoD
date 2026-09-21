#!/usr/bin/env bash
set -euo pipefail

printf '\n== Format ==\n'
dart format --output=none --set-exit-if-changed lib test

printf '\n== Architecture ==\n'
bash tool/verify_architecture.sh

printf '\n== Analyze ==\n'
flutter analyze

printf '\n== Test ==\n'
flutter test
