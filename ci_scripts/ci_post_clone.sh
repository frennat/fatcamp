#!/bin/sh
# Xcode Cloud runs this after cloning, before it builds.
#
# The web app is the product; the iOS project is a shell around it. So the job
# here is to get Node onto the build machine, stage the app into www/, and let
# Capacitor copy it into the iOS project. Xcode Cloud images ship Homebrew but
# not Node, which is why the first line exists.
set -e

echo "--- node ---"
brew install node
node --version
npm --version

echo "--- deps ---"
cd "$CI_WORKSPACE"
npm ci

echo "--- stage the web app and sync it into iOS ---"
npm run build
npx cap sync ios

echo "--- done ---"
