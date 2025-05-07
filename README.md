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

## Usage

Setup docker (engine or desktop) on the host and run

``` shell
$ docker run -d --rm --name ghcr.io/kzorba/terminal-emacs \
  -e EMACS_UID=$(id -u) \
  -e EMACS_GID=$(id -g) \
  -v "$HOME":/w \
  kzorba/terminal-emacs  
```

The above command is in the script `run-emacs-container.sh` and fetches the latest version of the image. Specific tags can be used later (for different versions of emacs for example).

The container will run an emacs in daemon mode (under `emacsuser`) and map the host user's home directory under `/w` in the container. Uid and gid of emacs user in the container will be adjusted to match the user on the host. With this all editing of host files (under the home directory) will keep proper ownership. 

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
