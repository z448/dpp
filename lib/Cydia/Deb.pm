#!/usr/bin/env perl

package Cydia::Deb;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
#use open qw< :encoding(UTF-8) >;
#use Cydia::Control qw(get_control);;
use JSON;
use File::Copy;
use Filesys::Tree;
use File::Path;
use Getopt::Std;
use Data::Dumper;

getopts('p:m:i:', \%opts);

my $control = sub {
    my $dist=shift;
    $api_url='http://api.metacpan.org/v0/release/'."$dist";
    $meta_j=qx!curl -sL $api_url!;
    $m = decode_json $meta_j;

    while (($key, $value) = each %$m) {
            print $key.' ------> '.$value."\n";
    }

    print $m->{'author'}.'lalalala'.$$m{'author'}."\n\n\n\n";
    
    my $deps = sub {
        print 'lllllllllllllll'.$m->{'version'};
        die;
    };
    my $deps = sub {
        my @deps;
        for my $dep(@{$m->{dependency}}){
            if ($$dep{relationship} eq 'requires'){
                push @deps, $$dep{module};
            }
        }
    return \@deps;
    };

    print '$m->{name} is '.$m->{name}."\n";
    print '$m{name} is '.$m{name}.'--'."\n";
    
    my $c = (
        'Package' => $key{'name'},
        'Name' => $m->{name},
        'Description' => $m->{'abstract'},
        'Author' => @{$m->{author}},
        'Version' => $m->{'version'},
        'Depends' =>  $deps->()
    );
return \%c;
};   #print $c{Depends};


my $pkg = sub {
    my $pm = shift; 
    #my $ct = $control->($pm);
     
    #print $c;
    my %meta_pkg = (
        'Prefix' => $opts{'p'},
        'Name' => $opts{'p'}.'-'.$ct{'name'},
        'path_dir' => 'build/'.$ct{'name'} . '/usr/local/lib/perl5/lib',
        'path_debian' => 'build/'.$ct{'Name'}.'/DEBIAN',
        'Depends' => @{$ct{'Depends'}},
        'pkg_name' => $opts{'p'}.'-'.lc($ct{'Name'}),
        'deb_name' => $opts{'p'}.'-'.lc($ct{'Name'})
    );
    return \%meta_pkg;

    #$b{'control'} = $control->($pm);
    #$b{'prefix'} = $opts{'p'};
    #$b{'name'} = $b{'prefix'}.'-'.lc($b{'control'}{'name'});
    #$b{'path_dir'} = 'build/' . $b{'name'} . '/usr/local/lib/perl5/lib';
    #$b{'path_debian'} = 'build/' . $b{'name'} . '/DEBIAN';
    #$b{'pkg_name'} = $b{'name'};
    #$b{'deb_name'} = $b{'name'}.'.deb';
    #return \%b;
};

print %{$control->($pm)};
    
sub build {
    my $build = $pkg->($opts{'m'}); 
    while (($key, $value) = each %$build) {
            print $key.' -> '.$value."\n";
    }
}

&build();

__DATA__
    while (($key, $value) = each %$m) {
        unless( $key eq 'control' ){
            print $key.' -> '.$value."\n";
        } else {
            print 'Depends: ';
            for( @{$$value{'dependency'}} ){
                s/\:\:/\-/g;
                if( $_->{phase} eq 'runtime' ){
                    print $_->{module}."\,\ ";
                }
            }
            print "\n";
        }
    }
}

build();
