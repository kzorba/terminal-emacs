# Terminal Emacs

This project contains Doom (GNU) Emacs with all necessary settings (and preferences) packaged in a docker container. Emacs only has terminal support (since it runs within the container as a daemon) and contains all settings for

``` text
- org mode agenda / time and task management
- Python development
- Rust development
- ...
```

See the doom files under `dotfiles` in the repository to see the activated options.

It is meant to support different Linux and MacOS environments uniformly provided docker (engine or docker desktop) runs on the host.

## Environment variables

The following environment variables can be used to parametrize the container:

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
|           | Used as the CWD of the emacs daemon process. Default value is '/w'   |
|           | so the container should mount user's $HOME under /w by default. You  |
|           | can change this to change the path were emacs will find the host     |
|           | user's files.                                                        |
|           | The container's boot scripts look for certain paths under $WORKDIR   |
|           | and create symbolic links (.gitconfig, .ssh, org).                   |
|-----------+----------------------------------------------------------------------|
```

## Usage

Setup docker (engine or desktop) on the host and run

``` shell
$ export WORKDIR="/w" && docker run -d --rm --name terminal-emacs \
  -e EMACS_UID=$(id -u) \
  -e EMACS_GID=$(id -g) \
  -e WORKDIR=$WORKDIR \
  -v "$HOME":"$WORKDIR" \
  ghcr.io/kzorba/terminal-emacs
```

The above command is in the script `run-emacs-container.sh` and fetches the latest version of the image. Specific tags can be used later (for different versions of emacs for example).

The container will run an emacs in daemon mode (under `emacsuser`) and map the host user's home directory under `$WORKDIR` in the container. Uid and gid of emacs user in the container will be adjusted to match the user on the host. With this all editing of host files (under the home directory) will keep proper ownership. 

You may get an emacs session in a terminal on the host using

``` shell
docker exec -ti -u emacsuser terminal-emacs emacsclient -c
```

We propose to create an alias in your shell for this (zsh example):

``` shell
# In .zshrc

alias ec='docker exec -ti -u emacsuser terminal-emacs emacsclient -c'
```

You can of course also create shortcuts for launching this via the MacOS dock or other window system panels.

You can stop the container (removing it completely) using

``` shell
docker stop terminal-emacs
```
