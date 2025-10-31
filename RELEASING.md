# Release Process for VistarClient

This document describes the process for releasing new versions of the VistarClient gem.

## Semantic Versioning

We follow [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** (x.0.0): Breaking changes to public API
- **MINOR** (0.x.0): New features, backward compatible
- **PATCH** (0.0.x): Bug fixes, backward compatible

## Pre-Release Checklist

- [ ] All tests passing (`bundle exec rspec`)
- [ ] RuboCop clean (`bundle exec rubocop`)
- [ ] Coverage ≥95% (check SimpleCov report)
- [ ] CHANGELOG.md updated with changes
- [ ] Version bumped in `lib/vistar_client/version.rb`
- [ ] Documentation updated (if API changes)
- [ ] README updated (if needed)
- [ ] All PRs merged to `main`

## Release Steps

### 1. Update Version and Changelog

```bash
# Edit version
vim lib/vistar_client/version.rb

# Update CHANGELOG.md
vim CHANGELOG.md
```

### 2. Commit Changes

```bash
git add lib/vistar_client/version.rb CHANGELOG.md
git commit -m "Bump version to X.Y.Z"
git push origin main
```

### 3. Create and Push Tag

```bash
git tag -a vX.Y.Z -m "Release version X.Y.Z"
git push origin vX.Y.Z
```

The GitHub Actions workflow will automatically:
- Run tests
- Build the gem
- Publish to RubyGems.org
- Create GitHub release

### 4. Verify Release

- Check [RubyGems.org](https://rubygems.org/gems/vistar_client)
- Check [GitHub Releases](https://github.com/Sentia/vistar_client/releases)
- Test installation: `gem install vistar_client`

## Rollback a Release

If a critical issue is found:

```bash
# Yank the gem (discouraged, only for critical security issues)
gem yank vistar_client -v X.Y.Z

# Release a patch version with fix immediately
```

## RubyGems API Key Setup

For maintainers: Add `RUBYGEMS_API_KEY` to GitHub Secrets:

1. Get API key from [RubyGems.org profile](https://rubygems.org/profile/edit)
2. Go to repo Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `RUBYGEMS_API_KEY`
5. Value: Your API key
6. Click "Add secret"

## Release Checklist Template

When releasing version X.Y.Z:

```markdown
## Release X.Y.Z

- [ ] Tests passing
- [ ] RuboCop clean
- [ ] Coverage ≥95%
- [ ] CHANGELOG.md updated
- [ ] Version bumped
- [ ] Committed and pushed to main
- [ ] Tag created: vX.Y.Z
- [ ] Tag pushed
- [ ] CI/CD passed
- [ ] Gem published to RubyGems
- [ ] GitHub release created
- [ ] Installation verified
```

## Version Numbering Guidelines

### MAJOR version (breaking changes)
- Removing public methods
- Changing method signatures
- Changing return values in breaking ways
- Renaming classes or modules
- Changing constructor arguments

### MINOR version (new features)
- Adding new public methods
- Adding new classes
- Adding optional parameters
- Deprecating features (with warnings)
- Internal improvements with no public API changes

### PATCH version (bug fixes)
- Fixing bugs
- Updating documentation
- Refactoring internal code
- Updating dependencies (non-breaking)
- Performance improvements

## Post-Release Communication

After release:

1. Announce on relevant channels (if applicable)
2. Update documentation sites if needed
3. Monitor for issues in first 24-48 hours
4. Respond to bug reports promptly

## Emergency Hotfix Process

For critical bugs in production:

1. Create hotfix branch from affected version tag
2. Fix the bug
3. Run full test suite
4. Bump PATCH version
5. Follow normal release process
6. Merge hotfix back to main
