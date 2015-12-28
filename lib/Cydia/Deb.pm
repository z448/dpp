#!/usr/bin/env perl

package Cydia::Deb;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
#use open qw< :encoding(UTF-8) >;
#use Cydia::Control qw(get_control);;
use JSON;
use Term::ANSIColor;
use Getopt::Std;
use File::Copy;
use Filesys::Tree;
use File::Path qw(make_path remove_tree);
use Data::Dumper;

getopts('m:p:', \%opts);

my $control = sub {
    $dist = shift;
    $meta_api_url = 'http://api.metacpan.org/v0/release/'."$dist";
    $meta_json = qx!curl -sL $meta_api_url!;
    $meta = decode_json $meta_json;
    return $meta;
};

my $pkg = sub {
    my $pm = shift; 
    my $cont = $control->($pm);

    my %b;
    $b{'prefix'} = $opts{'p'};
    $b{'name'} = $b{ prefix }.lc $$cont{'name'};
    $b{'package'} = $b{'name'};
    $b{'path_cpanm'} = 'build/' . $b{'name'} . '/usr/local/lib/perl5/lib';
    $b{'path_debian'} = 'build/' . $b{'name'} . '/DEBIAN';
    $b{'suffix'} = '.deb';
    $b{'path_control'} = $b{'path_debian'};
    $b{'dpkg_name'} = $b{'name'}.$b{'suffix'};
    $b{'control'} = \%$cont;
    return \%b;
};


sub meta {
    my $tuff = shift;
    my @dependency = ();

    $tuff =~ s/\:\:/\-/g;
    my $meta = $pkg->($tuff);

    
    my $deps = sub {
        my $c = shift;

        my $straight_deps = sub {
            my $all_deps = shift;
            my @deps = ();
            for( @{$all_deps} ){
                if( $_->{phase} eq 'runtime' and $_->{relationship} eq 'requires' ){
                    push @deps, lc $meta->{prefix}.$_->{module};
                }
            }

            my $deps_line = "Depends: ";
            for( @deps ){
                s/\:\:/\-/g;
                unless( $_ eq 'perl'){
                    $deps_line = $deps_line.$_.', ';
                }
            }
            return $deps_line;
        };

        for( keys %$c ){
            unless( $_ eq 'dependency' ){
                print $_.': '.$c->{$_}."\n";
            } else { 
                return $straight_deps->( $c->{$_} ).'perl'."\n"; # append perl w/o colon
            }
        }

    };

    print "\n".colored(['black on_white'], ' DPKG META ' )."\n";
    for( keys %$meta ){
        unless( $_ eq 'control' ){
            print $_.': '.$meta->{"$_"}."\n";
        } else { print $deps->($meta->{$_}) }
    }
    make_path( $meta->{path_cpanm}, $meta->{path_debian} );
    print "Tree has been created for build\n";
    print `tree build`;
}


meta($opts{'m'});


