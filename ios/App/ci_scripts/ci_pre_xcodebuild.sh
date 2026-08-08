#!/bin/sh
#
# Give every archive a unique build number.
#
# CURRENT_PROJECT_VERSION is pinned at 1 in the project, so every upload
# arrived as build 1. App Store Connect rejects a duplicate build number, so
# after the very first one nothing new ever reached TestFlight — the archive
# went green, the upload was refused, and the phone kept offering the old
# build with no update available.
#
# Xcode Cloud exports CI_BUILD_NUMBER, which increments on its own, so it is
# the natural source. Locally it is unset and this exits without touching
# anything, leaving normal builds at whatever the project says.
#
# Deliberately defensive. A previous ci_script broke four builds in a row by
# running `set -u` against an unset CI_WORKSPACE and exiting non-zero, which
# fails the whole archive. Nothing here can do that: no `set -e`, no `set -u`,
# and every path ends in exit 0.

if [ -z "$CI_BUILD_NUMBER" ]; then
  echo "ci_pre_xcodebuild: CI_BUILD_NUMBER unset, leaving the project alone"
  exit 0
fi

REPO="$CI_PRIMARY_REPOSITORY_PATH"
if [ -z "$REPO" ]; then
  # older images name it differently; fall back rather than give up
  REPO="$CI_WORKSPACE"
fi

PBX="$REPO/ios/App/App.xcodeproj/project.pbxproj"
if [ ! -f "$PBX" ]; then
  echo "ci_pre_xcodebuild: no project at $PBX, skipping"
  exit 0
fi

sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER;/g" "$PBX"
echo "ci_pre_xcodebuild: build number set to $CI_BUILD_NUMBER"
grep -m2 "CURRENT_PROJECT_VERSION" "$PBX"

exit 0
