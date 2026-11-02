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
- wolfSSL v5.9.4-stable, built twice as static libraries: `/opt/wolfssl` (`WOLFSSL_DIR`) with SNI, iPAddress matching, `WOLFSSL_ALWAYS_VERIFY_CB` and `KEEP_PEER_CERT`; `/opt/wolfssl-baseline` (`WOLFSSL_BASELINE_DIR`) from a bare `./configure`

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
