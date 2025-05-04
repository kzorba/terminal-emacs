# Terminal Emacs

This project contains Doom (GNU) Emacs with all necessary settings packaged in a docker container. Emacs only has terminal support (since it runs within the container) and contains all settings for

- org mode agenda / time and task management
- Python development
- Rust development

It is meant to support different Linux and MacOS environments uniformly provided docker (engine or docker desktop) runs on the host.

## Usage

Setup docker (engine or desktop) on the host and run

``` shell
docker run --name terminal-emacs ghcr.io/kzorba/terminal-emacs
```

for the latest version, or

``` shell
docker run --name terminal-emacs ghcr.io/kzorba/terminal-emacs:30.1
```

for the specific `30.1` version of emacs.

The container will run an emacs in daemon mode (under `emacsuser`). You may get an emacs session in a terminal using

``` shell
docker exec -ti -u emacsuser terminal-emacs emacsclient -c
```

We propose to create an alias in your shell for this (zsh example):

``` shell
# In .zshrc

alias emacsc='docker exec -ti -u emacsuser terminal-emacs emacsclient -c'
```
