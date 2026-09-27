#!/usr/bin/env bash
#set -x

export WORKDIR=$HOME
export USERNAME=emacsuser
export MY_NET=devnet

# Container configuration.
#
# Format:
#   "container_name:host_ssh_port"
#
# The order here is also the order in which containers are started.
#
# orgman: daily organization
# snake:  Python development
# rusty:  Rust development
# lambda: Emacs Lisp / Scheme development
# knr:    C development
#
CONTAINERS=(
	"orgman:2022"
	"snake:3022"
	"rusty:4022"
	#"lambda:5022"
	#"knr:6022"
)

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
			readlink "$socket_path" 2>/dev/null ||
				stat -f '%Y' "$socket_path" 2>/dev/null
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

	# Check and create the network we will attach to
	docker network inspect "$MY_NET" >/dev/null 2>&1 ||
		docker network create "$MY_NET"

	for entry in "${CONTAINERS[@]}"; do
		IFS=: read -r c port <<<"$entry"

		docker run -d --rm --name "$c" \
			--hostname "$c" \
			--net "$MY_NET" \
			-e WORKDIR="$WORKDIR" \
			-v "$HOME":"$WORKDIR" \
			-v "$REAL_SOCKET":"/var/run/docker.sock" \
			-p "$port":22 \
			--cap-add=SYS_PTRACE \
			--security-opt seccomp=unconfined \
			"${USER}/terminal-emacs-$c"

		echo "Container $c started successfully on port $port"
	done
else
	echo "/var/run/docker.sock does not exist. Is docker running?"
	exit 1
fi
