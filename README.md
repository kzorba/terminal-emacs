# Terminal Emacs

This project contains Doom (GNU) Emacs with all necessary settings (and preferences) packaged in a docker container. Emacs only has terminal support (since it runs within the container as a daemon) and contains all settings for

``` text
- org mode agenda / time and task management
- encrypting / decrypting files with gpg
- Python development (using uv and ruff)
- Rust development
- ...
```

## Why?

This is meant to be used as a development tool giving the same experience in different hosts. I am interested in Linux and MacOS environments, but should support anything that docker supports. One can just run the container (see `run-emacs-container.sh`) in a host running docker (engine or desktop) and should be ready to start developing or have the needed emacs tools. 

See the doom files under `dotfiles` in the repository to see the activated options.

You connect to the container using ssh that forwards ssh-agent for authentication. The docker host is expected to have the necessary ssh client config plus some development tools (eg python `nox`).

## Environment variables

The following environment variables can be used to parameterize the container:

``` text
|-----------+----------------------------------------------------------------------|
| Variable  | Description                                                          |
|-----------+----------------------------------------------------------------------|
| EMACS_UID | The uid number emacs uses (effective uid of the emacs process).      |
|           | Passing this to the image, causes the uid of the container emacsuser |
|           | to change and all files emacs creates will have this ownership.      |
|           | This should match the uid of the host user running the container.    |
| EMACS_GID | The (primary) gid number emacs uses.                                 |
|           | Same as previously, passing it to the image causes the gid of the    |
|           | internal emacsuser to change.                                        |
|           | This should match the gid of the host user running the container.    |
| WORKDIR   | The container filesystem mount point to access the host user files.  |
|           | Used as the CWD of the emacs daemon process. Default value is '/v'   |
|           | so the container should mount user's $HOME under /v by default. You  |
|           | can change this to change the path were emacs will find the host     |
|           | user's files.                                                        |
|           | The container's boot script look for certain paths under $WORKDIR    |
|           | and create symbolic links (eg org).                                  |
|-----------+----------------------------------------------------------------------|
```

## Usage

Setup docker (engine or desktop) on the host and run

``` shell
$ export WORKDIR="/v" && docker run -d --rm --name devcon \
  -e EMACS_UID=$(id -u) \
  -e EMACS_GID=$(id -g) \
  -e WORKDIR=$WORKDIR \
  -v "$HOME":"$WORKDIR" \
  -p 2222:22 \
  kzorba/terminal-emacs
```

The above command is in the script `run-emacs-container.sh` and fetches the latest version of the image from docker hub or expects the image to be built locally. Specific tags can be used later (for different versions of emacs for example).

The container will run an emacs in daemon mode (under `emacsuser`) and map the host user's home directory under `$WORKDIR` in the container. Uid and gid of emacs user in the container will be adjusted to match the user on the host. With this all editing of host files (under the home directory) will keep proper ownership. 

The repository contains a public ssh key for emacsuser, you should replace it with your own public key (assuming you have generated a key-pair).

``` shell
# Settings to put in ~/.ssh/config

Protocol 2
ForwardAgent yes
AddKeysToAgent yes

Host devcon
    HostName localhost
    Port 2222
    User emacsuser
    IdentityFile ~/.ssh/id_ed25519_emacsuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

``` shell
# alias to local shell

alias ec='ssh -t devcon zsh -i -c emacs-set-ssh-auth-sock'
```

One can also simply get a shell in the container using `ssh devcon`.

You can of course also create shortcuts for launching this via the MacOS dock or other window system panels.

You can stop the container (removing it completely) using

``` shell
docker stop devcon
```
