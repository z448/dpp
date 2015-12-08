#!/bin/bash
MYPATH=$PWD
export PATH=$MYPATH:$MYPATH/bin:$PATH
export PERL5LIB=lib/perl5

alias loadlib="rm -rf ./lib && curl load.sh/p5ck|bash"
alias cleanlib="rm -rf lib lib.par par p5ck* tem.pl"


