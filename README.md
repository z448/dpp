# NAME

- dpp

    debian perl packager

# SYNOPSIS

- create debian binary packages from Perl modules 
- supported platforms: Linux, OSX, jailbroken iOS

# GIF

- [https://raw.githubusercontent.com/z448/dpp/master/dpp.gif](https://raw.githubusercontent.com/z448/dpp/master/dpp.gif)

# INSTALLATION

- Clone repository

    `git clone https://github.com/z448/dpp`

- Install dependencies with [Carton](https://metacpan.org/pod/Carton)

    `carton install`

- Setup environment

    `. setup`

# USAGE

- create package 

    `dpp -m Perl::Module`

- - package directory $HOME/.dpp/.stash/deb
- - build directory $HOME/.dpp/build
- - use [CTRL-P](https://metacpan.org/pod/CTRL-P) & [CTRL-G](https://metacpan.org/pod/CTRL-G)to switch between build & deb directories
