![dpp logo](assets/logo50x50.jpg)

- dpp - debian perl packager

### SYNOPISIS

- Packs perl modules + dependencies into debian packages (.deb)

### INSTALLATION

- Clone repository

    `git clone https://github.com/z448/dpp`

- Install dependencies with [Carton](https://metacpan.org/pod/Carton)

    `carton install`

- Setup enviroment (this will switch you into build directory $HOME/.cypm/pool)

    `. setup`

### USAGE

- Pack module and it's dependencies 

    `dpp -m Perl::Module`
    

- deb directory ~/.cypm/.stash/deb
- pool (build) directory ~/.cypm/pool
- use [CTRL-P] & [CTRL-G] to switch between pool & deb directories



