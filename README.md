# Terminal Emacs

This project contains Doom (GNU) Emacs with all necessary settings (and preferences) packaged in a docker container. Emacs only has terminal support (since it runs within the container as a daemon) and contains all settings for

``` text
- org mode agenda / time and task management
- org mode presentations and Beamer / PDF export
- markdown file editing
- encrypting / decrypting files with gpg
- Python development (using uv and ruff)
- Rust development and debugging via codelldp / dape
- Editing files / development inside docker containers (tramp using docker: access)
- ...
```

## Why?

This is meant to be used as a development tool giving the same experience on different hosts. I am interested in Linux and MacOS environments, but should support anything that docker supports. One can just run the container (see `run-emacs-container.sh`) in a host running docker (engine or desktop) and should be ready to start developing or have the needed emacs tools.

See the doom files under `dotfiles` in the repository to see the activated options.

You connect to the container using ssh that forwards ssh-agent for authentication. The docker host is expected to have at least the necessary ssh client config. Although not strictly necessary, for Python development, the host should also contain `nox` and `uv` (to test / lint completely outside the development environment).

## Usage

Before everything (obviously) install docker engine or docker-desktop on the machine where terminal-emacs will run.
Then, you need to build the container on the host where you will be working on (use `build-emacs-container.sh`). After that run the container using `run-emacs-container.sh`. You can stop the container via `docker stop devcon`.

``` shell
$ cd WorkingArea
$ git clone https://github.com/kzorba/terminal-emacs.git
$ cd terminal-emacs
$ ./build-emacs-container.sh
...
(the build can take several minutes depending on the power of the host)
$ docker images | grep emacs
kzorba/terminal-emacs                                        latest        51b27e2f3c31   2 hours ago     6.29GB
$ ./run-emacs-container.sh
Docker socket: /var/run/docker.sock
ad69138bf8e1872dcb6831fb6a6995a2648f7d930002f4189c90c85b62e34622
Container 'devcon' started successfully
$ which ec
ec: aliased to ssh -t devcon zsh -i -c emacs-set-ssh-auth-sock
$ ec
(you are now in terminal-emacs viewing the Doom screen)
```

You will need to replace `emacsuser.pub` with another public key by generating an ssh-keypair (`ssh-keygen -t ed25519...`) keep the private key ONLY on your local working machine / laptop and do not put it on the remote servers. `ssh-agent` will take care of the authentication on the remote machines.

Here is the relevant ssh configuration on `.ssh/config`:

``` shell
(local machine running terminal-emacs)
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
    
(remote server running terminal-emacs)
Protocol 2
ForwardAgent yes

Host devcon
    HostName localhost
    Port 2222
    User emacsuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

A proposed alias for your shell:

``` shell
# alias to local shell

alias ec='ssh -t devcon zsh -i -c emacs-set-ssh-auth-sock'
```

One can also simply get a shell in the container using `ssh devcon`.

You can of course also create shortcuts for launching this via the MacOS dock or other window system panels.

You can stop the container (removing it completely) using

``` shell
$ docker stop devcon
```

## Extra Information

The main idea is that you run terminal-emacs on your local laptop / development host and on each remote server where you do development. 
During the container build process on each host, the generated image will contain a user with the same UID/GIDs as your host user, to be able to access and edit files on your home directory. The image will also get the correct value for the docker group since the host's docker socket is mounted in terminal-emacs. 

In this way, terminal-emacs can access and edit files inside other local docker containers, using `docker:user@container` method of tramp. You can also run `magit` on the other containers (provided the container you connect to has git available). This is how you can do remote development both on a server host and on remote docker containers.
