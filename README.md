![dpp logo](assets/logo50x50.jpg)

### NAME

- Debian Perl Packager 1.0

### SYNOPISIS

- create debian binary packages from Perl module

### GIF

![dpp](https://raw.githubusercontent.com/z448/dpp/master/dpp.gif)

### INSTALLATION

- Clone repository

    `git clone https://github.com/z448/dpp`

- Install dependencies with [Carton](https://metacpan.org/pod/Carton)

    `carton install`

- Setup enviroment

    `. setup`

### USAGE

- Pack module and it's dependencies 

    `dpp -m Perl::Module`
    

- deb directory ~/.cypm/.stash/deb
- build directory ~/.cypm/pool
- use [CTRL-P] & [CTRL-G] to switch between pool & deb directories



