#!/usr/bin/env perl

 package Cydia::Deb;
 use FindBin;
 use lib "$FindBin::Bin/../lib";
 use open qw< :encoding(UTF-8) >;
 use Cydia::Control qw(get_control);;
 use Term::ANSIColor;
 use File::Copy;
 use Filesys::Tree;
 use File::Path;
 use Getopt::Std;

 getopts('p:m:i:', \%opts);

 my $p5ver = sub { ...;
     # find perl5 version
 };

 my $build = sub {
     $b{'dpkg_prefix'} = $opts{'p'};
     $b{'dpkg_control'} = get_control($opts{'m'});
     $b{'dpkg_name'} = $b{'dpkg_control'}{'name'};
     $b{'path_dir'} = 'build/' . $b{'dpkg_name'} . '/usr/local/lib/perl5/lib';
     $b{'path_debian'} = 'build/' . $b{'dpkg_name'} . '/DEBIAN';
     return \%b;
 };


 my $query = sub {
     my $b = &$build;
     my $req = $opts{i};
     if ( defined $opts{'i'} ){
         print $$b{$req};
     } else {
         while (($key, $value) = each %$b) {
             print $key.' -> '.$$b{$key}."\n";
         }
     }
     print "\n\n";
 };

 &$query;
