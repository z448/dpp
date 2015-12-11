#!/usr/bin/env perl

package Cydia::Deb;
use Term::ANSIColor;
use IO::All;

my (@files,$dir);
unless(@ARGV){ $dir eq 'lib' } else { $dir eq $ARGV[0] }

@files=grep{/packlist/}io->dir('lib')->All;

for (@files){
    print "\n\n"; print colored(['bright_white'],$_)."\n";
    my @content=io($_)->slurp;

    for (@content){
        if(/\/usr\/local/){ next } else {
        print $_;
    }}
}
