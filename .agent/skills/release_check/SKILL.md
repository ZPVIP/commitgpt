---
name: Release Preparation
description: Steps to verify code quality and functionality before releasing.
---

# Release Preparation

## Running Tests

Run the test suite with:

```bash
bundle exec rspec
```

## Code Quality Checks

After completing development work, run these commands in order:

### 1. RuboCop (Linting)

```bash
bundle exec rubocop -f github
```

Fix any style violations before committing. The `-f github` flag outputs in a format suitable for CI/GitHub Actions.

### 2. Security Audit (Dependencies)

Check for vulnerable gem versions.

```bash
bundle exec bundle audit check --update
```

If vulnerabilities are found, update the affected gems:
```bash
bundle update [gem_name]
```
