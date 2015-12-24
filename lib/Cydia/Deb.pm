#!/usr/bin/env perl

package Cydia::Deb;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
#use open qw< :encoding(UTF-8) >;
#use Cydia::Control qw(get_control);;
use JSON::Tiny qw(decode_json);
use File::Copy;
use Filesys::Tree;
use File::Path;
use Getopt::Std;
use Data::Dumper;

getopts('p:m:i:', \%opts);

my $control = sub {
    $dist=shift;
    $meta_api_url='http://api.metacpan.org/v0/release/'."$dist";
    $meta_json=qx!curl -sL $meta_api_url!;
    $meta = decode_json $meta_json;
    return $meta;
};

my $pkg = sub {
    my $pm = shift; my %b;
    $b{'control'} = $control->($pm);
    $b{'prefix'} = $opts{'p'};
    $b{'name'} = $b{'control'}{'name'};
    $b{'path_dir'} = 'build/' . $b{'name'} . '/usr/local/lib/perl5/lib';
    $b{'path_debian'} = 'build/' . $b{'name'} . '/DEBIAN';
    return \%b;
};


sub build {
    my $m = $pkg->($opts{'m'}); 
    while (($key, $value) = each %$m) {
        unless( $key eq 'control' ){
            print $key.' -> '.$value."\n";
        } else {
            print $key."\:\n";
            for( @{$$value{'dependency'}} ){
                if( $_->{phase} eq 'runtime' ){
                    print "\t".$_->{module}."\n";
                }
            }
            print "\n";
        }
    }
}

build();
