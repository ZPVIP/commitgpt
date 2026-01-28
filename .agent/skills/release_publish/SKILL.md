---
name: Release Publishing
description: Publish the gem to Homebrew (GitHub Tap) and RubyGems.org.
---

# Release Publishing

## 1. Publish to Homebrew (GitHub Tap)

We use an automated script to handle the GitHub Release and Homebrew Formula update.

### Prerequisites
- `gh` CLI installed and authenticated (`gh auth login`).
- Clean working directory (commit all changes).

### Run Release Script
```bash
./scripts/release.sh <version>
# Example: ./scripts/release.sh 0.3.2
```

**This script will:**
1. Create and push Git Tag `v<version>`.
2. Create GitHub Release.
3. Update `Formula/commitgpt.rb` with new URL and SHA256.
4. Auto-push the updated Formula.

## 2. Publish to RubyGems

Publish the gem to the official RubyGems registry.

### Build
```bash
gem build commitgpt.gemspec
```

### Push
```bash
gem push commitgpt-<version>.gem
```
(You must be logged in via `gem signin` or have credentials configured)
