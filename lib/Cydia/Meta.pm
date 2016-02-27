package Cydia::Meta;

use 5.010;
use warnings;
use strict;

use JSON;
use File::Copy;
use Encode;
use List::MoreUtils qw(uniq);

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT = qw( control meta graph );
}

my $deps = sub {
    my $pm = shift;

    my $dep_dis = sub {
        my $m = shift;
        my $j = qx|curl -skL http://api.metacpan.org/v0/module/$m?join=release|;
        my $p  = decode_json( encode( 'utf8', $j )); 
        my $d = $p->{release}->{_source}->{distribution};
        return $d;
    };

    my $dep_pm = sub {
        my $m = shift;
        my $j = qx|curl -skL http://api.metacpan.org/v0/module/$m?join=release|;
        my $p  = decode_json( encode( 'utf8', $j )); 
        my @d = keys %{$p->{release}->{_source}->{metadata}->{prereqs}->{runtime}->{requires}};
        return \@d;
    };

    my $deps = '';
    my @deps_repeat = ();

    for ( @{$dep_pm->($pm)} ){
        push @deps_repeat, $dep_dis->($_);
    }

    my @deps_uniq = uniq @deps_repeat;
    
    for( @deps_uniq ){
        $deps = $deps . 'lib'.lc $_ .'-p5' . ', ' unless $_ eq 'perl'; 
    }
    $deps = $deps . 'perl';
    return $deps;
};

my $meta = sub {
    my $module = shift;
    my $metacpan = 'https://metacpan.org/pod/';
    my $meta_url = 'http://api.metacpan.org/v0/module/'."$module".'?join=release';
    my $graph = 'https://widgets.stratopan.com/wheel?q=';
    my $meta_j = qx!curl -sL $meta_url!;
#    print $meta_j;
    my $meta_p = decode_json( encode( 'utf8', $meta_j ) );
    my $m = $meta_p->{release}->{_source};
    my $prefix = 'lib';
     
    my $remote = {
        Name         => $m->{distribution},
        Version      => $m->{version},
        Author       => $m->{author},
        Section      => 'Perl',
        Description  => $m->{abstract},
        #description  => $meta_p->{description},
        Homepage     => $metacpan.$meta_p->{module}[0]->{name},
        Maintainer   => 'zedbe (z448) <z448@module.pm>',
        module_name  => $meta_p->{module}[0]->{name},
        release_date => $meta_p->{date},
        Architecture => 'iphoneos-arm',
        source_url   => $m->{download_url},
        deps_graph   => $graph.$m->{name}, #Moose-2.1205
        pod          => $meta_p->{pod},
        prefix       => 'lib',
        Package      => $prefix . lc $m->{distribution} . '-p5',
        pkg =>       => $prefix . lc $m->{distribution} . '-p5',
        build_path   => 'build/' . $m->{name} . '/usr/local/lib/perl5/lib',
        control_path => 'build/' . $m->{name} . '/DEBIAN/control',
        deb_name     => lc $m->{name} . '.deb',
        meta_api_url => $meta_url,
        Depends      => $deps->($module),
    };
    return $remote;

};

    
sub meta {
    my $pm = shift;
    my $m = $meta->( $pm );
    return $m;
}

sub control {
    my $pm  = shift;
    my $m = $meta->($pm);
    my @c = qw( Name Version Author Architecture Package Section Maintainer Homepage Depends Description );
    
    my $c= '';
    for( @c ){
        $c = $c . $_.': '.$m->{$_}."\n";
    }
    return $c;
}

sub graph {
    my $pm = shift;
    my $gui = $meta->($pm);
    my $open = 'open_chrome_single_window.sh';
    my $deps_graph=system("$open $gui->{deps_graph} &2>1 /dev/null");
    qx!$deps_graph!;
    return $gui;
}


__DATA__
