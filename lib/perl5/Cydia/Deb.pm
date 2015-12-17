#!/usr/bin/env perl

package Cydia::Deb;
use Term::ANSIColor;
use IO::All;
use File::Copy;

my (@files,$dir,$perl_ver);
$perl_ver = '5.18.2';

#print $cwd;
#unless($ARGV[0] =~ /.*/){ $dir = '~/cypan-build/usr/local/lib/perl5/lib' }
unless($ARGV[0] =~ /.*/){ $dir = 'build/usr/local/lib/perl5/lib' }
print $dir;
@files=grep{/packlist/}io->dir('build/usr/local/lib/perl5')->All;

my $b_dir_rx = qr/$dir/;
for (@files){
    print "\n\n"; print colored(['bright_white'],$_)."\n";
    my @content=io($_)->slurp;

      for (@content){
        unless(/build/){ next } else {
        print $_;
        move("build/usr/local/lib/perl5/lib/perl5", "build/usr/local/lib/perl5/lib/".$perl_ver);
        move("build/usr/local/lib/perl5/lib", "build/usr/local/lib/perl5/site_perl");
        }
    }
}
