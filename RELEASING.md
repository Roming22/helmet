# Release Process

Releases are created exclusively through the GitHub UI. GitHub Actions validates the tag and populates the release changelog automatically.

## How It Works

1. A human creates a release in the **GitHub UI** (pre-release checked)
2. GitHub creates the tag on `main` and fires `release.published`
3. GHA runs `make release` → validates tag format, runs CI, populates changelog
4. When ready, the human edits the release and unchecks "pre-release" to promote

## Version Guidelines

All versions follow [Semantic Versioning](https://semver.org/):

```
vMAJOR.MINOR.PATCH[-beta.N|-rc.N]
```

| Phase | Example | Breaking Changes |
|-------|---------|-----------------|
| Beta (`v0.x`) | `v0.1.0-beta.1` | Allowed |
| Release Candidate | `v1.0.0-rc.1` | Not allowed |
| Stable (`v1.x+`) | `v1.2.3` | Major bump required |

## Pre-Release Checklist

Before creating a release in the GitHub UI:

- [ ] CI green on `main`
- [ ] `make lint` passes locally
- [ ] `make test-unit` passes
- [ ] `make security` passes
- [ ] `make verify-mod` confirms `go.mod`/`go.sum` are clean
- [ ] Documentation updated for any API or behavior changes

## Creating a Release

1. Go to **Releases → Draft a new release** in the GitHub UI
2. Choose `main` as the target branch
3. Enter the tag (e.g., `v0.1.0-beta.1`) — GitHub creates it on publish
4. Check **"Set as a pre-release"**
5. Click **"Publish release"**

The GHA workflow runs automatically. Monitor it at the repository's Actions tab.

## Promoting a Pre-Release

When the release is validated and ready for consumers:

1. Go to **Releases** in the GitHub UI
2. Edit the release
3. Uncheck **"Set as a pre-release"**
4. Save — the release is now marked as `latest`

No workflow is triggered on promotion.

## Troubleshooting

### Failed Workflow

The release and tag already exist in the UI. To retry:

```bash
# Delete the release and tag
gh release delete <tag> --yes
git push origin :refs/tags/<tag>

# Fix the issue, then re-publish via GitHub UI
```

### Retracting a Bad Release

If consumers already pulled a bad version, add a `retract` directive to `go.mod` and publish a new release:

```go
module github.com/redhat-appstudio/helmet

retract v0.1.0-beta.1 // Published with broken API
```

## Reference

- [Contributing Guide](CONTRIBUTING.md)
- [Makefile Targets](Makefile)
- [Semantic Versioning](https://semver.org/)
