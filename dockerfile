FROM debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc
LABEL Description="Image for running CppUTest"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Add LLVM and GitHub CLI apt repositories
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg wget \
    && wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key \
        | gpg --dearmor > /usr/share/keyrings/llvm-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-19 main" \
        > /etc/apt/sources.list.d/llvm.list \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf automake clang-19 clang-format-19 clang-tidy-19 cmake cppcheck g++ gcc gdb gh git lcov libclang-19-dev libssl-dev libtool llvm-19-dev make openssh-client sudo zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Set clang-format-19 and clang-tidy-19 as defaults
RUN update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-19 100 \
 && update-alternatives --install /usr/bin/clang-tidy  clang-tidy  /usr/bin/clang-tidy-19   100

WORKDIR /home/cpputest
RUN git clone --depth 1 --branch v4.0 https://github.com/cpputest/cpputest.git . \
 && autoreconf . -i \
 && ./configure \
 && make install

ENV CPPUTEST_HOME=/home/cpputest

WORKDIR /home/legacy-build
RUN git clone https://github.com/jwgrenning/legacy-build.git . \
 && git submodule update --init \
 && bash test/all-tests.sh

# Build include-what-you-use against clang-19. The clang_19 branch matches
# the installed Clang's library ABI; mismatched IWYU/Clang versions silently
# produce wrong include suggestions because IWYU embeds Clang's parser.
# Pinned to the same recipe as cpputest-clang so both images ship the same
# IWYU binary.
WORKDIR /tmp/iwyu
RUN git clone --depth 1 --branch clang_19 https://github.com/include-what-you-use/include-what-you-use.git . \
 && cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/usr/lib/llvm-19 -DCMAKE_INSTALL_PREFIX=/usr/local \
 && cmake --build build --parallel "$(nproc)" \
 && cmake --install build \
 && cd / && rm -rf /tmp/iwyu

# wolfSSL, twice, for the SolidSyslog WolfSsl pack (E34). The pack compiles
# against whatever build an integrator has, so CI proves it on two: one with
# the options the pack asks for, and a bare ./configure baseline that is what
# a default build gives. Both are the same pinned release, static libraries
# only so nothing needs a loader path. The tag is annotated, so the SHA
# checked is the commit it points at. The "# renovate:" comment is read by
# Renovate (renovate.json), which opens a pull request moving the tag and the
# SHA together when wolfSSL releases; see README.md.
# renovate: datasource=git-tags packageName=https://github.com/wolfSSL/wolfssl.git versioning=regex:^v(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)-stable$
ARG WOLFSSL_TAG=v5.9.4-stable
ARG WOLFSSL_SHA=3c5eead44904df64e6a5a1f4ebdce377d35a849a
WORKDIR /tmp/wolfssl
RUN git clone --depth=1 --branch=${WOLFSSL_TAG} https://github.com/wolfSSL/wolfssl.git . \
 && [ "$(git rev-parse HEAD)" = "${WOLFSSL_SHA}" ] \
 && ./autogen.sh \
 && ./configure --prefix=/opt/wolfssl-baseline --enable-static --disable-shared \
      --disable-examples --disable-crypttests \
 && make -j"$(nproc)" \
 && make install \
 && make distclean \
 && ./configure --prefix=/opt/wolfssl --enable-static --disable-shared \
      --disable-examples --disable-crypttests \
      --enable-sni --enable-ip-alt-name \
      CPPFLAGS="-DWOLFSSL_ALWAYS_VERIFY_CB -DKEEP_PEER_CERT" \
 && make -j"$(nproc)" \
 && make install \
 && cd / && rm -rf /tmp/wolfssl
ENV WOLFSSL_DIR=/opt/wolfssl
ENV WOLFSSL_BASELINE_DIR=/opt/wolfssl-baseline

ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN mkdir -p /home/src \
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && chown -R ${USERNAME}:${USERNAME} /home/cpputest /home/legacy-build /home/src

USER ${USERNAME}

WORKDIR /home/src
