# Terminal Emacs

This project contains Doom (GNU) Emacs container variants with all necessary settings (and preferences) optimized for various tasks. Emacs only has terminal support (since it runs within the container as a daemon).
We maintain the following image variants:

```text
orgman: daily organization (org-mode / doc writing / review projects)
snake: Python development
rusty: Rust development
lambda: Emacs lisp / scheme development
knr: C development

All development variants come with an AI agent tool (pi.dev)
```

To see what exactly is included in each image, see the relevant Dockerfiles. The images built should be as much as possible reproducable, so we pin software versions wherever possible. Doom Emacs helps a lot with this since its architecture is based around reproducibility.

Initially this project created one big (fat) image with all tools but practice has shown that it is better to maintain several smaller images for each task. The user may choose which of the variants he wants to run on a host.

## Why?

This is meant to be used as a development tool giving the same experience on different hosts. I am interested in Linux and MacOS environments, but should support anything that docker supports. One can just run the container variant(s) he/she wants (see `run-emacs-containers.sh`) in a host running docker (engine or desktop) and should be ready to start developing or have the needed emacs tools.

See the doom files under `dotfiles/doom` in the repository to see the activated options for each container variant.

You connect to each container using ssh that forwards ssh-agent for authentication. The docker host is expected to have at least the necessary ssh client config (see examples below).

## Usage

Before everything (obviously) install docker engine or docker-desktop (or any other tool that can run containers) on the machine where terminal-emacs will run.
Then, you need to build the container variants on the host where you will be working on (use `build-emacs-containers.sh`). After that run the containers using `run-emacs-containers.sh`. 
You can stop each container via `docker stop <container>`.

The build and run scripts contain a setting to select the variants that should be built (by default all variants are built)

```shell
$ cd WorkingArea
$ git clone https://github.com/kzorba/terminal-emacs.git
$ cd terminal-emacs
$ ./build-emacs-containers.sh
...
(the build can take several minutes depending on the power of the host)
===>
===> Building orgman
===>
...
===>
===> Building snake
===>
...
===>
===> Building knr
===>
...

$ docker images | grep terminal-emacs
kzorba/terminal-emacs-knr:latest                                    5a044d154794       3.21GB             0B
kzorba/terminal-emacs-lambda:latest                                 2eac5815e343       2.81GB             0B
kzorba/terminal-emacs-orgman:latest                                 17595f8f501f       1.22GB             0B   U
kzorba/terminal-emacs-rusty:latest                                  ca62210f0b23       3.64GB             0B
kzorba/terminal-emacs-snake:latest                                  a2bf40424ef5       2.32GB             0B   U

$ which ec
ec () {
        local host=${1:-orgman}
        ssh -t "$host" zsh -i -c emacs-set-ssh-auth-sock
}
$ ec rusty
(you are now in terminal-emacs viewing the Doom screen)
```

You will need to replace `emacsuser.pub` with another public key by generating an ssh-keypair (`ssh-keygen -t ed25519...`) keep the private key ONLY on your local working machine / laptop and do not put it on the remote servers. `ssh-agent` will take care of the authentication on the remote machines.

Here is the relevant ssh configuration (example) on `.ssh/config`. It is recommended to keep the same ports for the container variants on the local and each remote server you work on.

```shell
(local machine running terminal-emacs)
Host orgman
    HostName localhost
    Port 2022
    User emacsuser
    IdentityFile ~/.ssh/id_ed25519_emacsuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host snake
    HostName localhost
    Port 3022
    User emacsuser
    IdentityFile ~/.ssh/id_ed25519_emacsuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host rusty
    HostName localhost
    Port 4022
    User emacsuser
    IdentityFile ~/.ssh/id_ed25519_emacsuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host lambda
    HostName localhost
    Port 5022
    User emacsuser
    IdentityFile ~/.ssh/id_ed25519_emacsuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host knr
    HostName localhost
    Port 6022
    User emacsuser
    IdentityFile ~/.ssh/id_ed25519_emacsuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    
(remote server running terminal-emacs)
Protocol 2
ForwardAgent yes

Host orgman
    HostName localhost
    Port 2022
    User emacsuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
...
Host snake
    HostName localhost
    Port 3022
    User emacsuser
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
...
```

A proposed function for your shell:

```shell
# function to local shell

ec() {
    local host=${1:-orgman}
    ssh -t "$host" zsh -i -c emacs-set-ssh-auth-sock
}
```

One can also simply get a shell in a container using `ssh <container>`.

You can of course also create shortcuts for launching this via the MacOS dock or other window system panels.

You can stop a container (removing it completely) using

```shell
$ docker stop <container>
```

## Extra Information

The main idea is that you run terminal-emacs image variants on your local laptop / development host and on each remote server where you do development. 
During the container build process on each host, the generated images will contain a user with the same UID/GIDs as your host user, to be able to access and edit files on your home directory. The image will also get the correct value for the docker group since the host's docker socket is mounted in terminal-emacs. 

In this way, terminal-emacs can access and edit files inside other local docker containers, using `docker:user@container` method of tramp. You can also run `magit` on the other containers (provided the container you connect to has git available). This is how you can do remote development both on a server host and on remote docker containers.
