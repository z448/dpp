#!/usr/bin/env perl

package Cydia::Meta;
use 5.010;
use warnings;
use strict;
#use FindBin;
#use lib "$FindBin::Bin/../lib";
#use open qw< :encoding(UTF-8) >;
use JSON;
use Term::ANSIColor;
use Getopt::Std;
use File::Copy;
use Filesys::Tree;
use File::Path qw(make_path remove_tree);
use Data::Dumper;
use Data::Printer;
use Archive::Tar;
use PAR::Dist;

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT = qw( control );
}

my $meta = sub {
    my ( $module, $prefix ) = @_;
    my $metacpan = 'https://metacpan.org/pod/';
    my $meta_url = 'http://api.metacpan.org/v0/module/'."$module".'?join=release';
    my $graph = 'https://widgets.stratopan.com/wheel?q=';
    my $meta_j = qx!curl -sL $meta_url!;
#    print $meta_j;
    my $meta_p = decode_json $meta_j;
    my $m = $meta_p->{release}->{_source};
     
    #my $deps = sub {
    #    my $strings = shift;
    #    my @d = ();
    #    for( keys %$strings ){ push @d, "$_"."\,\ " } 
    #    return \@d;
    #};

    my $remote = {
        Name         => $m->{distribution} . '-perl5',
        Version      => $m->{version},
        Author       => $m->{author},
        Section      => 'Perl',
        Description  => $m->{abstract},
        #Description  => $m->{abstract}."\n".$m->{release}->{description},  
        Homepage     => $metacpan.$meta_p->{module}[0]->{name},
        Maintainer   => 'z8',
        #Depends      => $deps->($m->{metadata}->{prereqs}->{runtime}->{requires}),
        deps         => $m->{metadata}->{prereqs}->{runtime}->{requires},
        module_name  => $meta_p->{module}[0]->{name},
        release_date => $meta_p->{date},
        source_url   => $m->{download_url},
        deps_graph   => $graph.$m->{name}, #Moose-2.1205
        #pod         => $meta_p->{pod},
        prefix       => $prefix,
        Package      => $prefix . lc $m->{distribution} . '-p5',
        build_path   => 'build/' . $m->{name} . '/usr/local/lib/perl5/lib',
        control_path => 'build/' . $m->{name} . '/DEBIAN/control',
        deb_name     => lc $m->{name} . '.deb',
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
    
sub control {
    my $pm = shift; my $px = shift;;
    my $m = $meta->($pm, $px);
    p $m;

    print colored(["black on_white"], 'CONTROL')."\n";
    my @c = qw( Name Version Author Package Section Maintainer Homepage Description);
    for( @c ){
        print $_.': '.$m->{$_}."\n";
    }

    print "Depends: ";
    my @deps = keys %{$m->{deps}};
    for( @deps ){ 
        s/\:\:/\-/g;
        unless( $_ eq $deps[$#deps] ){
            print "$px".lc $_.'-p5, ';
        } else { print "$px".lc $_.'-p5, perl5'."\n" }
    }

}

control(@ARGV);

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
