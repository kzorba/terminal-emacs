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

# Support a truecolor terminal. You can comment xterm-direct and
# uncomment the other 2 lines, could be more portable.
# ENV TERM="xterm-256color"
# ENV COLORTERM="truecolor"
ENV TERM="xterm-direct"

# This directory should map to the user's home directory in the host.
# A startup script checks for it to create stuff in emacsuser's
# home directory.
ENV WORKDIR="/h"

# Install runtime dependencies, tools to build vterm-module
# and our dev tools
RUN apt-get update && apt-get install -y \
    biber \
    build-essential \
    ca-certificates \
    cmake \
    direnv \
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

# Delete ubuntu user, create an emacsuser, install oh-my-zsh,
# doom, uv, ruff, rustup
RUN deluser --remove-home ubuntu && \
    useradd -d /home/emacsuser -m -s /bin/zsh emacsuser && \
    passwd -d emacsuser && \
    /sbin/setuser emacsuser sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    /sbin/setuser emacsuser sh -c "git clone https://github.com/doomemacs/doomemacs.git ~/.emacs.d" && \
    /sbin/setuser emacsuser sh -c "curl -LsSf https://astral.sh/uv/install.sh | sh" && \
    /sbin/setuser emacsuser sh -c "curl -LsSf https://astral.sh/ruff/install.sh | sh" && \
    /sbin/setuser emacsuser sh -c "curl https://sh.rustup.rs -sSf | sh -s -- -y" && \
    /sbin/setuser emacsuser zsh -i -c "rustup component add rust-analyzer" && \
    /sbin/setuser emacsuser zsh -i -c "rustup show" && \
    /sbin/setuser emacsuser zsh -i -c "rust-analyzer --version"

# Copy dotfiles
COPY dotfiles/doom /home/emacsuser/.doom.d
COPY dotfiles/zsh/zshrc /home/emacsuser/.zshrc
COPY dotfiles/git/gitconfig /home/emacsuser/.gitconfig

# libvterm
RUN chown -R emacsuser:emacsuser /home/emacsuser && \
    /sbin/setuser emacsuser zsh -i -c "doom sync -u -b --force && doom env" && \
    # Build vterm-module (C code involved)
    /sbin/setuser emacsuser zsh -i -c \
    "cmake -S ~/.emacs.d/.local/straight/repos/emacs-libvterm -B ~/.emacs.d/.local/straight/repos/emacs-libvterm/build" && \
    /sbin/setuser emacsuser zsh -i -c \
    "make -C ~/.emacs.d/.local/straight/repos/emacs-libvterm/build" && \
    /sbin/setuser emacsuser zsh -i -c \
    "cp ~/.emacs.d/.local/straight/repos/emacs-libvterm/vterm-module.so ~/.emacs.d/.local/straight/build-30.2/vterm/" && \
    /sbin/setuser emacsuser zsh -i -c \
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
    /sbin/setuser emacsuser zsh -i -c \
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
RUN mkdir /home/emacsuser/.ssh && \
    chmod 700 /home/emacsuser/.ssh && \
    cat /tmp/emacsuser.pub >> /home/emacsuser/.ssh/authorized_keys && \
    chown -R emacsuser:emacsuser /home/emacsuser/.ssh && \
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
