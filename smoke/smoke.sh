#!/usr/bin/env bash
# Smoke-tests a built cpputest image from inside it. It checks the tree a bump
# changes, not any project built on the image: each tool answers, CppUTest
# builds, links and runs a test, and both wolfSSL builds link and report the
# release the dockerfile pins. See README.md.
#
# Usage, from the repository root:
#   docker run --rm -v "$PWD:/smoke:ro" <image> /smoke/smoke/smoke.sh /smoke/dockerfile
set -euo pipefail

dockerfile="$1"
here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

pinned_tag() {
    sed -n "s/^ARG $1_TAG=//p" "${dockerfile}"
}

echo "== tools"
for tool in gcc g++ make cmake clang-19 clang-format clang-tidy cppcheck \
    include-what-you-use lcov gdb gh git; do
    version="$("${tool}" --version 2>&1 | sed -n 1p)" || {
        echo "${tool}: ${version}" >&2
        exit 1
    }
    printf '%-22s %s\n' "${tool}" "${version}"
done

echo "== CppUTest"
g++ "${here}/AllTests.cpp" -I"${CPPUTEST_HOME}/include" \
    -L"${CPPUTEST_HOME}/lib" -lCppUTest -o "${work}/AllTests"
"${work}/AllTests"

echo "== wolfSSL"
expected="$(pinned_tag WOLFSSL | sed -e 's/^v//' -e 's/-stable$//')"
for dir in "${WOLFSSL_DIR}" "${WOLFSSL_BASELINE_DIR}"; do
    gcc "${here}/WolfSslVersion.c" -I"${dir}/include" \
        "${dir}/lib/libwolfssl.a" -lm -lpthread -o "${work}/WolfSslVersion"
    "${work}/WolfSslVersion" "${expected}"
    echo "${dir}: ${expected}"
done

echo "== smoke passed"
