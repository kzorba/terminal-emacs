# Stage 1: Build Emacs (nox version)
FROM ubuntu:noble AS builder
LABEL org.opencontainers.image.authors="Kostas Zorbadelos <kzorba@nixly.net>"

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc-14 g++-14 libgccjit-14-dev \
    make libc6-dev \
    libgnutls28-dev \
    libjansson-dev \
    libtree-sitter-dev \
    libxml2-dev \
    zlib1g-dev \
    pkg-config \
    libncurses-dev \
    texinfo \
    wget \
    git \
    ca-certificates

ENV EMACS_VERSION="30.2"

# Download and build Emacs
RUN cd /tmp && \
    wget http://ftpmirror.gnu.org/emacs/emacs-${EMACS_VERSION}.tar.gz && \
    tar -xzf emacs-${EMACS_VERSION}.tar.gz && \
    cd emacs-${EMACS_VERSION} && \
    export CC=gcc-14 && \
    export CXX=g++-14 && \
    ./configure \
      --without-x --without-x-toolkit \
      --without-gconf --without-gsettings \
      --without-imagemagick \
      --without-sound --without-dbus \
      --without-gpm && \
    make -j"$(nproc)" && \
    make install DESTDIR=/emacs-install

# Stage 2: Create runtime image with all tools
FROM phusion/baseimage:noble-1.0.2
LABEL org.opencontainers.image.authors="Kostas Zorbadelos <kzorba@nixly.net>"

# Accept UID, GID, USERNAME as build arguments (with defaults).
# These are parameters for the effective user emacs runs inside the container
# the docker group should give access to the host's docker if available.
ARG USER_UID=1000
ARG USER_GID=1000
ARG USERNAME=emacsuser
ARG DOCKER_GID=1000

ENV USERNAME=${USERNAME}
ENV USER_UID=${USER_UID}
ENV USER_GID=${USER_GID}
ENV DOCKER_GID=${DOCKER_GID}

# Support a truecolor terminal. You can comment xterm-direct and
# uncomment the other 2 lines, could be more portable.
# ENV TERM="xterm-256color"
# ENV COLORTERM="truecolor"
ENV TERM="xterm-direct"

# This directory should map to the user's home directory in the host.
# We just put an initial value here, but we expect it will be set
# accordingly, when the container is run.
ENV WORKDIR="/h"

# Install runtime dependencies, tools to build vterm-module
# our dev tools and docker cli
RUN apt-get update && \
    apt-get install -y ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y \
    biber \
    build-essential \
    cmake \
    direnv \
    docker-ce-cli \
    fd-find \
    git \
    git-lfs \
    libgnutls30 \
    libjansson4 \
    libncurses6 \
    libgccjit0 \
    libtool-bin \
    libtree-sitter0 \
    libvterm-dev \
    lldb \
    ncurses-term \
    ripgrep \
    shfmt \
    pandoc \
    texlive \
    texlive-bibtex-extra \
    texlive-extra-utils \
    texlive-lang-greek \
    texlive-latex-extra \
    texlive-pictures \
    texlive-xetex \
    zsh

# Copy Emacs from builder
COPY --from=builder /emacs-install/usr/local /usr/local

# Delete ubuntu user, create a ${USERNAME}, install oh-my-zsh,
# doom, uv, ruff, rustup
RUN deluser --remove-home ubuntu && \
    groupadd -g ${USER_GID} -f ${USERNAME} && \
    groupadd -g ${DOCKER_GID} -o docker && \
    useradd -d /h/${USERNAME} -m -s /bin/zsh -u ${USER_UID} -g ${USER_GID} -G docker ${USERNAME} && \
    passwd -d ${USERNAME} && \
    /sbin/setuser ${USERNAME} sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    /sbin/setuser ${USERNAME} sh -c "git clone https://github.com/doomemacs/doomemacs.git ~/.emacs.d" && \
    /sbin/setuser ${USERNAME} sh -c "curl -LsSf https://astral.sh/uv/install.sh | sh" && \
    /sbin/setuser ${USERNAME} sh -c "curl -LsSf https://astral.sh/ruff/install.sh | sh" && \
    /sbin/setuser ${USERNAME} sh -c "curl https://sh.rustup.rs -sSf | sh -s -- -y" && \
    /sbin/setuser ${USERNAME} zsh -i -c "rustup component add rust-analyzer" && \
    /sbin/setuser ${USERNAME} zsh -i -c "rustup show" && \
    /sbin/setuser ${USERNAME} zsh -i -c "rust-analyzer --version"

# Copy dotfiles
COPY dotfiles/doom /h/${USERNAME}/.doom.d
COPY dotfiles/zsh/zshrc /h/${USERNAME}/.zshrc
COPY dotfiles/git/gitconfig /h/${USERNAME}/.gitconfig

# libvterm
RUN chown -R ${USERNAME}:${USERNAME} /h/${USERNAME} && \
    /sbin/setuser ${USERNAME} zsh -i -c "doom sync -u -b --force && doom env" && \
    # Build vterm-module (C code involved)
    /sbin/setuser ${USERNAME} zsh -i -c \
    "cmake -S ~/.emacs.d/.local/straight/repos/emacs-libvterm -B ~/.emacs.d/.local/straight/repos/emacs-libvterm/build" && \
    /sbin/setuser ${USERNAME} zsh -i -c \
    "make -C ~/.emacs.d/.local/straight/repos/emacs-libvterm/build" && \
    /sbin/setuser ${USERNAME} zsh -i -c \
    "cp ~/.emacs.d/.local/straight/repos/emacs-libvterm/vterm-module.so ~/.emacs.d/.local/straight/build-30.2/vterm/" && \
    /sbin/setuser ${USERNAME} zsh -i -c \
    "make -C ~/.emacs.d/.local/straight/repos/emacs-libvterm/build clean"

# codelldb
RUN ARCH="$(uname -m)" && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        CODELLDB=codelldb-linux-arm64.vsix; \
    else \
        CODELLDB=codelldb-linux-x64.vsix; \
    fi && \
    curl -L \
      -o /tmp/$CODELLDB \
      https://github.com/vadimcn/codelldb/releases/download/v1.11.8/$CODELLDB && \
    /sbin/setuser ${USERNAME} zsh -i -c \
    "mkdir -p ~/.doom.d/debug-adapters && unzip /tmp/$CODELLDB -d ~/.doom.d/debug-adapters/codelldb" && \
    # Clean up the build tools and apt files
    apt-get purge -y cmake libtool-bin && \
    apt-get auto-remove -y && \
    apt-get clean  && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/apt/lists/*

# Adjust the container to the host environment
COPY scripts/adjust_env.sh /etc/my_init.d/90_adjust_env.sh
RUN chmod +x /etc/my_init.d/90_adjust_env.sh

# Enable ssh service
## Install our SSH key for emacsuser
COPY emacsuser.pub /tmp/emacsuser.pub
RUN mkdir /h/${USERNAME}/.ssh && \
    chmod 700 /h/${USERNAME}/.ssh && \
    cat /tmp/emacsuser.pub >> /h/${USERNAME}/.ssh/authorized_keys && \
    chown -R ${USERNAME}:${USERNAME} /h/emacsuser/.ssh && \
    rm -f /tmp/emacsuser.pub && \
    rm -f /etc/service/sshd/down && \
    /etc/my_init.d/00_regen_ssh_host_keys.sh

# Copy the service script
# emacs daemon
RUN mkdir /etc/service/emacs-daemon
COPY scripts/emacs-daemon.sh /etc/service/emacs-daemon/run
RUN chmod +x /etc/service/emacs-daemon/run

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
