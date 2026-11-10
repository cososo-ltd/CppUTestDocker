# CppUTest Docker

A base Docker image for TDD development with GCC and [CppUTest](http://cpputest.github.io/). Suitable for use across multiple C/C++ projects.

## Contents

- GCC 14 (via the official `gcc:14` base image)
- CppUTest v4.0
- CMake
- cppcheck
- clang-format, clang-tidy
- gdb, lcov
- [GitHub CLI (`gh`)](https://cli.github.com/)
- [James Grenning's legacy-build toolkit](https://github.com/jwgrenning/legacy-build)
- autoconf, automake, libtool
- wolfSSL at the release `dockerfile` pins, built twice as static libraries: `/opt/wolfssl` (`WOLFSSL_DIR`) with SNI, iPAddress matching, `WOLFSSL_ALWAYS_VERIFY_CB` and `KEEP_PEER_CERT`; `/opt/wolfssl-baseline` (`WOLFSSL_BASELINE_DIR`) from a bare `./configure`

## Keeping the wolfSSL pin current

[Renovate](https://docs.renovatebot.com/), installed on the organisation as
the Mend GitHub App, opens a pull request when wolfSSL publishes a patch or
minor release, moving `WOLFSSL_TAG` and `WOLFSSL_SHA` together. The
publishing workflow builds the image on that pull request, so a release that
no longer clones, gates or builds cleanly fails there. `renovate.json` holds
the configuration.

Renovate finds the pin by the `# renovate:` comment immediately above the
pair. It names the `git-tags` datasource, which resolves the annotated tag to
the commit the `git rev-parse HEAD` gate compares, the clone URL, and a regex
versioning, because Renovate's default reads the `-stable` suffix as a
pre-release and would offer nothing.

A new major version does not open a pull request. It is listed on the
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

## Usage

Pull the image from the GitHub Container Registry:

```
docker pull ghcr.io/davidcozens/cpputest:latest
```

Run tests by mounting your project directory (containing your `CMakeLists.txt` or `Makefile`) to `/home/src`:

```
docker run -v <path>:/home/src ghcr.io/davidcozens/cpputest make
```

Where `<path>` is the fully qualified path to your project folder.

The `CPPUTEST_HOME` environment variable is set to `/home/cpputest` inside the container.

For production use and traceability, prefer a specific SHA tag over `latest`. Each build is tagged with the commit SHA it was built from (e.g. `sha-abc1234`). Available tags can be found on the [package page](https://github.com/davidcozens/CppUTestDocker/pkgs/container/cpputest):

```
docker run -v <path>:/home/src ghcr.io/davidcozens/cpputest:sha-<commit-sha> make
```

## Building

The image is built and pushed to the [GitHub Container Registry](https://ghcr.io) automatically on each push to the `main` branch.

To build locally:

```
docker build -t cpputest .
```
