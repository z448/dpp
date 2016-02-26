#!/usr/bin/env perl

package Cydia::Meta;
use 5.010;
use warnings;
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use open qw< :encoding(UTF-8) >;
use JSON;
use File::Copy;
use Filesys::Tree;
use Data::Printer;
use Encode;

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT = qw( control  queue  meta );
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
    for ( @{$dep_pm->($pm)} ){
        $deps .= $deps . 'lib-'.$dep_dis->($_) .'-p5' . ', ';
    }
    $deps = $deps . 'perl';
    return $deps;
    #my $deps_inline = $control_format->(\@deps);
    #my $deps = $control_format->(\@deps);
    #my @deps$dep_dis->($pm)};
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
    my( $remote ) = ();


     
    $remote = {
        Name         => $m->{distribution},
        Version      => $m->{version},
        Author       => $m->{author},
        Section      => 'Perl',
        Description  => $m->{abstract},
        #description  => $meta_p->{description},
        Homepage     => $metacpan.$meta_p->{module}[0]->{name},
        Maintainer   => 'zb (z8) <_p@module.pm>',
        #Depends      => $deps->($m->{metadata}->{prereqs}->{runtime}->{requires}),
        #deps         => $m->{metadata}->{prereqs}->{runtime}->{requires},
        Dependencies => $deps->($module),
        module_name  => $meta_p->{module}[0]->{name},
        release_date => $meta_p->{date},
        Architecture => 'iphoneos-arm',
        source_url   => $m->{download_url},
        deps_graph   => $graph.$m->{name}, #Moose-2.1205
        pod          => $meta_p->{pod},
        prefix       => 'lib',
        Package      => $prefix . lc $m->{distribution} . '-p5',
        build_path   => 'build/' . $m->{name} . '/usr/local/lib/perl5/lib',
        control_path => 'build/' . $m->{name} . '/DEBIAN/control',
        deb_name     => lc $m->{name} . '.deb',
        meta_api_url => $meta_url,
        #dependencies => $deps->($module),
    };
    return $remote;


};

    # PAR build
    #    #my $dist = blib_to_par(); # make a PAR file using ./blib/
    #    #install_par($dist);       # install it into the system
    #    #uninstall_par($dist);     # uninstall it from the system
    #    #sign_par($dist);          # sign it using Module::Signature
    #    #verify_par($dist);        # verify it using Module::Signature
    #
    #    #install_par("http://foo.com/DBI-1.37-MSWin32-5.8.0.par"); # works too
    #    #install_par("http://foo.com/DBI-1.37"); # auto-appends archname + perlver
    #    #install_par("cpan://SMUELLER/PAR-Packer-0.975"); # uses CPAN author directory

    # JSON defaults
    #   add & rw defaults from json here;
    #
    
sub meta {
    my $pm = shift;
    my $m = $meta->{ $pm };
    $m;
}

sub control {
    my $pm  = shift;
    my $m = $meta->($pm);
    my @c = qw( Name Version Author Architecture Package Section Maintainer Homepage Dependencies Description );
    
    my $c= '';
    for( @c ){ $c = $c . $_.': '.$m->{$_}."\n" }
    return $c;
}

#sub queue {
#     my $pm = shift;
#     my $m = $meta->($pm);
#     my @q = keys %{$m->{deps}};
#     return \@q;
# }
#print control(@ARGV);

#print "Queueing library dependencies:\n".@{queue_control(@ARGV)};

#for( @{queue_control(@ARGV)} ){
#        print "Generating control for $_ \n";
#        print control($_)."\n";
#}

__DATA__

Name Version Author Package Depends Section Maintainer Homepage Description   


sub meta_pm {
    #my $c = $control->($ARGV[0]);
    my $c = $meta->(@ARGV);
    p $c;
    #my $open = 'open_chrome_single_window.sh';
    #my $deps_graph=system("$open $c->{deps_graph} &2>1 /dev/null");
    #qx!$deps_graph!;
    #for( keys %$c ){
    #    say $_.' -> '.$c->{ $_ };
    #}
    
    #print "Depends: ";
    #print @{$$c{Depends}};
    #print "\n";
    #p $paths->( @ARGV );
}

meta_pm();
