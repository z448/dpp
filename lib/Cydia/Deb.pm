#!/usr/bin/env perl

package Cydia::Deb;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
#use open qw< :encoding(UTF-8) >;
#use Cydia::Control qw(get_control);;
use JSON;
use Getopt::Std;
use File::Copy;
use Filesys::Tree;
use File::Path;
use Data::Dumper;
use IO::All;
use File::Copy;

getopts('m:p:', \%opts);

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
    $b{'path_control'} = 
    $b{'prefix'} = $opts{'p'};
    $b{'name'} = $b{ prefix }.lc $b{'control'}{'name'};
    $b{'package'} = $b{'name'};
    $b{'path_cpanm'} = 'build/' . $b{'name'} . '/usr/local/lib/perl5/lib';
    $b{'path_debian'} = 'build/' . $b{'name'} . '/DEBIAN';
    $b{'suffix'} = '.deb';
    $b{'path_control'} = $b{'path_debian'};
    $b{'dpkg_name'} = $b{'name'}.$b{'suffix'};
    return \%b;
};


sub meta {
    my @control = ();
    my $m = $pkg->($opts{'m'}); 
    while (($key, $value) = each %$m) {
        unless( $key eq 'control' ){
            print $key.' -> '.$value."\n";
            push @control, $key."\: "."$value";
        } else {
            print 'depends'."\:\ ";
            my @deps = @{$$value{'dependency'}};

            for( @deps ){
                $_->{'module'} =~ s/\:\:/\-/g;
                if( $_->{phase} eq 'runtime' and $_->{relationship} eq 'requires' ){
                    unless( $_->{module} eq $deps[$#deps] ){
                        print $m->{'prefix'}.lc $_->{module}."\,\ ";
                    } else { print lc $_->{module} };
                        push @control, $_->{module};
                }
            }
            print "\n";
        }
    }
}
meta();

