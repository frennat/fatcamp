#!/bin/sh
# Xcode Cloud runs this after cloning, before it builds.
#
# It lives beside App.xcodeproj because that is where Xcode Cloud looks — a
# ci_scripts directory at the repository root is silently ignored when the
# project is in a subdirectory.
#
# The web assets are committed, so this is a refresh and not a requirement.
# Nothing in here is allowed to fail the build: if Node cannot be installed we
# archive what is already in the repo, which is correct by construction because
# `npm run sync` runs before every commit.
set -u

echo "--- node ---"
if command -v brew >/dev/null 2>&1; then
  brew install node || echo "brew install node failed; carrying on"
fi

if command -v npm >/dev/null 2>&1; then
  echo "node $(node --version), npm $(npm --version)"
  cd "$CI_WORKSPACE" || exit 0
  npm ci                  || { echo "npm ci failed; using committed assets"; exit 0; }
  npm run build           || { echo "build failed; using committed assets";  exit 0; }
  npx cap sync ios        || { echo "cap sync failed; using committed assets"; exit 0; }
  echo "--- web assets refreshed ---"
else
  echo "--- node unavailable; archiving the committed web assets ---"
fi
exit 0
