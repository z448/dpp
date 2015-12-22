export PATH=$PWD/bin:$PATH
export PERL5LIB=$PWD/local/lib/perl5
    
function setup {
    rm -rf $PWD/local
    mkdir $PWD/local
    rm -rf $PWD/build
    mkdir -p $PWD/build/usr/local/lib/perl5/site_perl
    mkdir $PWD/build/DEBIAN
    touch $PWD/build/DEBIAN/control
}

    echo -e '   - source this file'
    echo -e "\e[33m. env \e[0m"
    echo -n '   - to install dependencies use Carton '
    echo -e "\n\e[33mcarton install \e[0m"
    echo -n '   - if you dont have it install it via cpan '
    echo -e "\n\e[33mcpan Carton \e[0m"
    echo '   - anytime you want to reset env, do '
    echo -e "\e[31msetup \e[0m\n\n"