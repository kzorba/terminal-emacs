#!/usr/bin/env bash

export WORKDIR=$HOME
export USERNAME=emacsuser

# Function to resolve symlink (portable)
resolve_socket() {
    local socket_path="/var/run/docker.sock"

    if [[ ! -e "$socket_path" ]]; then
        echo ""
        return 1
    fi

    # Check if it's a symlink
    if [[ -L "$socket_path" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS: resolve using readlink or stat
            readlink "$socket_path" 2>/dev/null || stat -f '%Y' "$socket_path" 2>/dev/null
        else
            # Linux: use readlink -f
            readlink -f "$socket_path"
        fi
    else
        # Not a symlink, return as-is
        echo "$socket_path"
    fi
}

# Start docker daemon before this.
if [ -S "/var/run/docker.sock" ]; then
    # Resolve the actual socket path
    REAL_SOCKET=$(resolve_socket)

    if [[ -z "$REAL_SOCKET" ]]; then
        echo "Error: Could not resolve Docker socket"
        exit 1
    fi

    echo "Docker socket: /var/run/docker.sock"
    if [[ "$REAL_SOCKET" != "/var/run/docker.sock" ]]; then
        echo "  -> resolves to: $REAL_SOCKET"
    fi

    docker run -d --rm --name devcon \
        --hostname devcon \
        -e WORKDIR=$WORKDIR \
        -v "$HOME":"$WORKDIR" \
        -v "$REAL_SOCKET":"/var/run/docker.sock" \
        -v devcon_cache_volume:/h/${USERNAME}/.cache \
        -v devcon_share_volume:/h/${USERNAME}/.local/share \
        -p 2222:22 \
        --cap-add=SYS_PTRACE \
        --security-opt seccomp=unconfined \
        kzorba/terminal-emacs

    echo "Container 'devcon' started successfully"
else
    echo "/var/run/docker.sock does not exist. Is docker running?"
    exit 1
fi
