export PERL5LIB=$PWD/local/lib/perl5:$PWD/lib:~/.dpp/.stash/tools/usr/share/perl5:$PERL5LIB
export PATH=$PWD:$PWD/local/bin:$PATH 

#export DPP=~/.dpp

bind '"\C-p":"cd ~/.dpp/build && clear && pwd\n"';
bind '"\C-g":"cd ~/.dpp/.stash/deb && clear && pwd;\n"';
