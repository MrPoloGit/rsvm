# Use Alpine (musl). 
FROM alpine:3.20

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Basic deps + Python + dev tools + glibc-compat + bash (the installer uses bash)
RUN apk add --no-cache \
      bash \
      coreutils \
      findutils \
      grep \
      sed \
      gawk \
      make \
      git \
      wget \
      curl \
      ca-certificates \
      tar \
      xz \
      unzip \
      gzip \
      patchelf \
      libc6-compat \
      gcompat \
      shadow \
      sudo \
      python3 \
      py3-pip \
      python3-dev \
      build-base

# Make a non-root user that Codespaces/VS Code likes
# (uid 1000 is conventional; adjust if your host uses a different uid)
RUN adduser -D -u 1000 vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_vscode && \
    chmod 0440 /etc/sudoers.d/99_vscode

# Where we’ll install the HDL tools so PATH can be set globally
ENV TOOL_DIR=/opt/tools
RUN mkdir -p ${TOOL_DIR}
WORKDIR ${TOOL_DIR}

# Install OSS CAD Suite and zachjs/sv2v using the provided installer
# This mirrors:
#   wget -O - https://raw.githubusercontent.com/sifferman/hdl-tool-installer/main/install | \
#     bash -s -- . --oss-cad-suite --zachjs-sv2v
RUN wget -O - https://raw.githubusercontent.com/sifferman/hdl-tool-installer/main/install \
    | bash -s -- . --oss-cad-suite --zachjs-sv2v

# Make them available on PATH for all users/shells
ENV PATH="${TOOL_DIR}/oss-cad-suite/bin:${TOOL_DIR}/zachjs-sv2v:${PATH}"

# Nice-to-have: keep pip modern + don’t cache wheels to save space
RUN python3 -m pip install --no-cache-dir --upgrade pip

# Default workspace path Codespaces uses
WORKDIR /workspaces

# Switch to the non-root user by default
USER vscode

# By default, containers use /bin/sh; we prefer bash for a nicer shell
SHELL ["/bin/bash", "-lc"]
