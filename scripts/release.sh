#!/bin/bash
set -e

# Usage: ./scripts/release.sh 0.3.0
VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: $0 <version>"
  echo "Example: $0 0.3.0"
  exit 1
fi
TAG="v$VERSION"
REPO="ZPVIP/commitgpt" # Ensure this matches your repo

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    exit 1
fi

echo "🚀 Preparing release $TAG..."

# 1. Ensure clean state
if [[ -n $(git status --porcelain) ]]; then
  echo "Error: Working directory not clean. Please commit changes first."
  exit 1
fi

# 2. Check if tag exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "Tag $TAG already exists. Skipping tagging."
else
  echo "Step 1: Creating and pushing tag $TAG..."
  git tag "$TAG"
  git push origin "$TAG"
fi

# 3. Create GitHub Release
if gh release view "$TAG" >/dev/null 2>&1; then
  echo "Release $TAG already exists."
else
  echo "Step 2: Creating GitHub Release..."
  gh release create "$TAG" --title "$TAG" --notes "Release $TAG"
fi

# 4. Calculate SHA256
URL="https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz"
echo "Step 3: Calculating SHA256 for $URL..."
# Fetch first few bytes to check existence? No, just checksum.
# Wait a second for GitHub to generate tarball
sleep 2

SHA=$(curl -L -s --fail "$URL" | shasum -a 256 | awk '{print $1}')

if [ -z "$SHA" ]; then
  echo "Error: Failed to calculate SHA256. Release might not be ready or URL is wrong."
  exit 1
fi

echo "SHA256: $SHA"

# 5. Update Formula
echo "Step 4: Updating Formula/commitgpt.rb..."
FORMULA_FILE="Formula/commitgpt.rb"

# Update URL
sed -i '' "s|url \".*\"|url \"$URL\"|" "$FORMULA_FILE"
# Update SHA256
sed -i '' "s|sha256 \".*\"|sha256 \"$SHA\"|" "$FORMULA_FILE"

echo "Formula updated!"

# 6. Push Formula Update
echo "Step 5: Pushing updated formula to repository..."
git add "$FORMULA_FILE"
git commit -m "Update Homebrew formula for $TAG"
git push

echo "✅ Done! Users can now install via brew tap $REPO (or your tap repo) and brew install commitgpt."
