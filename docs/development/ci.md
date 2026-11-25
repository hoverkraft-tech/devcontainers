# Development, CI, and publishing

## Local checks

Install Node.js from [`.node-version`](../../.node-version), npm, Docker, and
Make. Docker must be running for linting and feature tests.

```bash
npm ci --ignore-scripts
make docs
make lint
make test
```

The lockfile pins the devcontainer CLI. `make test` runs the existing asdf tests
against Debian, Ubuntu, and the dev container base image, followed by the
scenarios in [`test/asdf/scenarios.json`](../../test/asdf/scenarios.json).
The scenarios cover a selected asdf version and installing kubectl as a
non-root user. Builds download images, features, asdf, and kubectl, so they
require network access. The CLI removes its test containers after each run.

`make lint` uses the same Hoverkraft Super-Linter image as CI. Local linting
checks the working tree; commit messages are checked by CI and pull request
titles by the shared semantic workflow. Generated `src/*/README.md` files are
linted too. `make docs` runs the official generator, corrects its table header
terminology, and formats its output with the pinned Prettier version.
After committing generated documentation, `npm run docs:check` verifies that
regeneration leaves it unchanged.

## Workflow structure

| Entry point                                                                      | Events                                                  | Behavior                                                                    |
| -------------------------------------------------------------------------------- | ------------------------------------------------------- | --------------------------------------------------------------------------- |
| [`__pull-request-ci.yml`](../../.github/workflows/__pull-request-ci.yml)         | Pull requests targeting `main`, merge groups            | Run shared CI.                                                              |
| [`__main-ci.yml`](../../.github/workflows/__main-ci.yml)                         | Pushes to `main`, manual runs, weekly schedule          | Run shared CI and update generated feature documentation after main pushes. |
| [`semantic-pull-request.yml`](../../.github/workflows/semantic-pull-request.yml) | Pull request creation, reopening, title edits, updates  | Check the title against the repository's commitlint policy.                 |
| [`prepare-release.yml`](../../.github/workflows/prepare-release.yml)             | Pull request creation, reopening, title edits, updates  | Apply the shared release labels. Fork pull requests are skipped.            |
| [`release.yml`](../../.github/workflows/release.yml)                             | Manual runs and a weekly schedule on the default branch | Plan, validate, draft, publish features, then publish the GitHub release.   |

[`__shared-ci.yml`](../../.github/workflows/__shared-ci.yml) delegates generated
documentation checks, JavaScript CodeQL analysis, and dependency review to
`ci-github-nodejs`'s `continuous-integration.yml`. Its build command regenerates documentation on main pushes and runs
`docs:check` for pull requests, schedules, and releases; Node.js lint and test jobs are disabled because the shared linter
and container test workflow cover this repository.

The remaining jobs run Hoverkraft's shared linter, CodeQL for Actions, action pin
checks, feature schema validation, and
[`__test-features.yml`](../../.github/workflows/__test-features.yml).
Failed checks fail CI. Matrix jobs finish independently to expose failures on
each image. There is no global-scenarios job because this collection has no
`test/_global` scenarios.

The shared report workflow runs after linting, validation, and tests, including
when they fail. It collects native lint reports and job outcomes. The
devcontainer CLI does not produce a structured test report here; inspect its
job logs for individual assertions. Reports do not replace the producer jobs
as required checks in branch rules.

After main-push CI succeeds, the documentation job runs the same pinned generator
and formatter and opens a documentation PR when files changed. The repository
GitHub App uses `CI_BOT_APP_CLIENT_ID` and `CI_BOT_APP_PRIVATE_KEY` with contents
and pull request write permissions so that the documentation PR triggers CI.
Schedules and releases do not publish documentation changes.

CI and releases use `GITHUB_TOKEN`. Feature validation and tests have read-only
repository access. Fork pull requests run on `pull_request`; shared reporting
keeps summaries without posting comments.

## Adding or changing a feature

Keep metadata and `install.sh` in `src/<feature>/`. Put assertions in
`test/<feature>/test.sh`; every named scenario in `scenarios.json` needs a shell
script with the same name. Add new features to both test matrices. Reuse
existing scenarios when they cover the behavior being changed.

Keep tests in the CLI's native `test/<feature>/` directory. The publisher includes
everything under `src/<feature>/` in the feature archive, so colocating tests
there would also ship them to users.

Feature readmes are generated by the devcontainer CLI. Change
`devcontainer-feature.json` or `src/<feature>/NOTES.md`, then run `make docs` and
commit the result. Put usage instructions in `NOTES.md`; the generator includes
them in the feature readme alongside its options. CI checks that the generated
output is current. Do not edit generated readmes directly.

## Publishing

Update each changed feature's `version` in `devcontainer-feature.json` using
SemVer and commit its regenerated documentation before publishing. Feature
versions and their `feature_<id>_<version>` tags remain independent of the
collection's GitHub release version; the workflow does not bump feature metadata.

The weekly `release.yml` run follows the
[Hoverkraft release process](https://github.com/hoverkraft-tech/ci-github-publish/blob/main/docs/usage/release.md).
It can also be run manually from `main`; other branches and tags are skipped.

1. `release/plan` computes the collection's release identity and detects changes
   since its last GitHub release. No-change runs skip later jobs.
2. Shared CI validates that source revision and its committed documentation.
3. `release/create` creates a draft for the planned tag and validated commit.
4. `devcontainers/action` publishes feature packages from the same commit using
   their declared versions.
5. `release/update` publishes the GitHub release after feature publishing succeeds.

If feature publishing fails, `release/delete` removes only the draft. Already
uploaded feature packages are retained, and the native publisher skips existing
versions when the workflow is rerun. Documentation is validated before release
and is not changed after package publication.

New GHCR packages default to private. Set the feature packages and collection
metadata package to public in their package settings for public consumption.
The collection namespace is `ghcr.io/hoverkraft-tech/devcontainers`.

To list a new collection in the public feature index, submit its namespace to
[`collection-index.yml`](https://github.com/devcontainers/devcontainers.github.io/blob/gh-pages/_data/collection-index.yml).
