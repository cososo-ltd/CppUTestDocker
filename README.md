# CppUTest Docker

A base Docker image for TDD development with GCC and [CppUTest](http://cpputest.github.io/). Suitable for use across multiple C/C++ projects.

## Contents

- GCC and G++ from Debian bookworm (the `debian:bookworm-slim` base image)
- CppUTest v4.0
- CMake
- cppcheck
- clang-format, clang-tidy
- gdb, lcov
- [GitHub CLI (`gh`)](https://cli.github.com/)
- [James Grenning's legacy-build toolkit](https://github.com/jwgrenning/legacy-build)
- autoconf, automake, libtool
- wolfSSL at the release `dockerfile` pins, built twice as static libraries: `/opt/wolfssl` (`WOLFSSL_DIR`) with SNI, iPAddress matching, `WOLFSSL_ALWAYS_VERIFY_CB` and `KEEP_PEER_CERT`; `/opt/wolfssl-baseline` (`WOLFSSL_BASELINE_DIR`) from a bare `./configure`

## Keeping the pins current

[Renovate](https://docs.renovatebot.com/), installed on the organisation as
the Mend GitHub App, opens a pull request when wolfSSL publishes a patch or
minor release, moving `WOLFSSL_TAG` and `WOLFSSL_SHA` together. It does the
same for the digest the `FROM` line pins `debian:bookworm-slim` at, and for
the SHA-pinned actions in the publishing workflow. The publishing workflow builds the image on that pull request and smokes it (see
below), so a release that no longer clones, gates, builds or links fails
there. `renovate.json` holds the configuration.

Renovate finds the pin by the `# renovate:` comment immediately above the
pair. It names the `git-tags` datasource, which resolves the annotated tag to
the commit the `git rev-parse HEAD` gate compares, the clone URL, and a regex
versioning, because Renovate's default reads the `-stable` suffix as a
pre-release and would offer nothing.

A new wolfSSL major does not open a pull request. It is listed on the
Dependency Dashboard issue, and opens one only when ticked there: under
SolidSyslog's support statement a new major is platform work, not a bump. A
dashboard entry means no decision has been recorded yet; once the epic
exists, an `allowedVersions` rule in `renovate.json` names it and the entry
goes.

CodeRabbit skips a Renovate pull request (`.coderabbit.yaml`): the build on
the pull request is the check. If a bump needed a hand-pushed change to
build, ask for the review with a `@coderabbitai review` comment.

The images layered on this one carry the same wolfSSL release as source, so a
bump here is followed by one there.

## What merges itself

A Renovate pull request whose `build-and-push` check passes, smoke included,
merges itself: `renovate.json` sets `automerge`, and branch protection on
`main` requires that check, so GitHub's auto-merge waits for it. The publish
that follows sends solid-syslog its bump pull request, and that one is merged
by hand there. Nobody needs to look at this repository while bumps are green.

Two kinds of pull request come to the maintainer instead, by assignment, which
is a GitHub notification:

- one whose checks fail - Renovate assigns an automerge pull request only then;
- a major of anything, which never merges itself. An upstream major is
  platform work, and a GitHub Action's major is where its inputs change, which
  a pull request cannot exercise for the login, push and notify steps that run
  only on `main`.

## The smoke

The publishing workflow builds the image into the runner's Docker and runs
`smoke/smoke.sh` inside it before anything is pushed, on pull requests and on
`main` alike. It checks what a bump can change, not any project built on the
image:

- every tool listed above answers `--version`;
- CppUTest builds, links and runs a one-test executable from `CPPUTEST_HOME`;
- each wolfSSL build, `WOLFSSL_DIR` and `WOLFSSL_BASELINE_DIR`, links a program
  whose header and library both report the release `WOLFSSL_TAG` names.

Whether a project still compiles against a new release is that project's own
CI's question, asked by the bump pull request the publish sends it.

## Usage

Pull the image from the GitHub Container Registry:

```
docker pull ghcr.io/cososo-ltd/cpputest:latest
```

Run tests by mounting your project directory (containing your `CMakeLists.txt` or `Makefile`) to `/home/src`:

```
docker run -v <path>:/home/src ghcr.io/cososo-ltd/cpputest make
```

Where `<path>` is the fully qualified path to your project folder.

The `CPPUTEST_HOME` environment variable is set to `/home/cpputest` inside the container.

For production use and traceability, prefer a specific SHA tag over `latest`. Each build is tagged with the commit SHA it was built from (e.g. `sha-abc1234`). Available tags can be found on the [package page](https://github.com/cososo-ltd/CppUTestDocker/pkgs/container/cpputest):

```
docker run -v <path>:/home/src ghcr.io/cososo-ltd/cpputest:sha-<commit-sha> make
```

## Building

The image is built and pushed to the [GitHub Container Registry](https://ghcr.io) automatically on each push to the `main` branch.

Once it is pushed, the workflow sends an `image-published` event to
[solid-syslog](https://github.com/cososo-ltd/solid-syslog), whose Image Bump
workflow opens the pull request that moves every reference onto the new digest
and runs CI on it. The event is sent with a token minted from the release
GitHub App for solid-syslog, from the `RELEASE_PLEASE_APP_ID` and
`RELEASE_PLEASE_PRIVATE_KEY` organisation secrets; the App itself is not
installed here. The images layered on this one pin it by digest and Renovate
moves that pin, so a push here is followed by a bump there.

To build locally:

```
docker build -t cpputest .
```
