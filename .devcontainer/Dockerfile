# Versions are not written here: the image reads .tool-versions so the
# container, CI and a developer's laptop cannot drift apart.
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive \
    VCPKG_ROOT=/opt/vcpkg \
    VCPKG_DISABLE_METRICS=1 \
    PATH=/opt/cmake/bin:/opt/vcpkg:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip zip tar pkg-config \
      build-essential mold ccache gdb lldb \
      python3 python3-pip python3-venv \
      sudo locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# The single source of tool pins, plus the reader used by CI.
COPY .tool-versions /tmp/pins/.tool-versions
COPY scripts/tool-version.sh /tmp/pins/scripts/tool-version.sh

RUN set -eux; \
    pin() { bash /tmp/pins/scripts/tool-version.sh "$1"; }; \
    gcc_major="$(pin gcc)"; gcc_major="${gcc_major%%.*}"; \
    clang_major="$(pin clang)"; clang_major="${clang_major%%.*}"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      "gcc-${gcc_major}" "g++-${gcc_major}" \
      "clang-${clang_major}" "clang-tidy-${clang_major}" "clang-format-${clang_major}" \
      "lld-${clang_major}" "libc++-${clang_major}-dev" "libc++abi-${clang_major}-dev"; \
    update-alternatives --install /usr/bin/gcc gcc "/usr/bin/gcc-${gcc_major}" 100; \
    update-alternatives --install /usr/bin/g++ g++ "/usr/bin/g++-${gcc_major}" 100; \
    update-alternatives --install /usr/bin/clang clang "/usr/bin/clang-${clang_major}" 100; \
    update-alternatives --install /usr/bin/clang++ clang++ "/usr/bin/clang++-${clang_major}" 100; \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy "/usr/bin/clang-tidy-${clang_major}" 100; \
    update-alternatives --install /usr/bin/clang-format clang-format "/usr/bin/clang-format-${clang_major}" 100; \
    update-alternatives --install /usr/bin/clangd clangd "/usr/bin/clangd-${clang_major}" 100 || true; \
    rm -rf /var/lib/apt/lists/*

# CMake and Ninja come from upstream release archives: the distro versions lag
# behind the pins, and these two are the tools the presets depend on directly.
RUN set -eux; \
    pin() { bash /tmp/pins/scripts/tool-version.sh "$1"; }; \
    arch="$(uname -m)"; \
    cmake_version="$(pin cmake)"; \
    curl -fsSL -o /tmp/cmake.tar.gz \
      "https://github.com/Kitware/CMake/releases/download/v${cmake_version}/cmake-${cmake_version}-linux-${arch}.tar.gz"; \
    mkdir -p /opt/cmake; \
    tar -xzf /tmp/cmake.tar.gz -C /opt/cmake --strip-components=1; \
    rm /tmp/cmake.tar.gz; \
    ninja_version="$(pin ninja)"; \
    case "$arch" in \
      aarch64) ninja_asset=ninja-linux-aarch64.zip ;; \
      *)       ninja_asset=ninja-linux.zip ;; \
    esac; \
    curl -fsSL -o /tmp/ninja.zip \
      "https://github.com/ninja-build/ninja/releases/download/v${ninja_version}/${ninja_asset}"; \
    unzip -q /tmp/ninja.zip -d /usr/local/bin; \
    chmod +x /usr/local/bin/ninja; \
    rm /tmp/ninja.zip; \
    cmake --version; ninja --version

# vcpkg at the pinned baseline commit, so the container resolves the same port
# versions as CI.
RUN set -eux; \
    pin() { bash /tmp/pins/scripts/tool-version.sh "$1"; }; \
    git clone https://github.com/microsoft/vcpkg.git "$VCPKG_ROOT"; \
    git -C "$VCPKG_ROOT" checkout --detach "$(pin vcpkg)"; \
    "$VCPKG_ROOT/bootstrap-vcpkg.sh" -disableMetrics; \
    chmod -R a+rX "$VCPKG_ROOT"

RUN python3 -m pip install --no-cache-dir --break-system-packages pre-commit gcovr

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid "$USER_GID" "$USERNAME" \
    && useradd --uid "$USER_UID" --gid "$USER_GID" -m -s /bin/bash "$USERNAME" \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" \
    && chmod 0440 "/etc/sudoers.d/$USERNAME"

# vcpkg writes its binary cache here; keeping it outside the source tree means a
# rebuilt container still reuses prebuilt ports.
ENV VCPKG_DEFAULT_BINARY_CACHE=/home/$USERNAME/.cache/vcpkg
RUN mkdir -p "$VCPKG_DEFAULT_BINARY_CACHE" && chown -R "$USER_UID:$USER_GID" "/home/$USERNAME/.cache"

USER $USERNAME
ENV LANG=en_US.UTF-8
