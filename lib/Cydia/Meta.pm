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
    our @EXPORT = qw( meta );
}

my $control = sub {
    my ( $module, $prefix ) = @_;
    my $metacpan = 'https://metacpan.org/pod/';
    my $meta_url = 'http://api.metacpan.org/v0/module/'."$module".'?join=release';
    my $graph = 'https://widgets.stratopan.com/wheel?q=';
    my $meta_json = qx!curl -sL $meta_url!;
    my $meta = decode_json $meta_json;
    my $m = $meta->{release}->{_source};
     
    my $deps = sub {
        my $strings = shift;
        my @d = ();
        for( keys %$strings ){ push @d, "$_"."\,\ " } 
        return \@d;
    };

    my $remote = {
        Name         => $m->{name},
        Version      => $m->{version},
        Author       => $m->{author},
        Description  => $m->{abstract}."\n".$meta->{release}->{description},  
        Homepage     => $metacpan.$meta->{module}[0]->{name},
        Depends      => $deps->($m->{metadata}->{prereqs}->{runtime}->{requires}),
        module_name  => $meta->{module}[0]->{name},
        release_date => $meta->{date},
        source_url   => $m->{download_url},
        deps_graph   => $graph.$m->{name}, #Moose-2.1205
        #pod         => $meta->{pod},
        prefix       => $prefix,
        package      => $prefix . lc $m->{name},
        build_path   => 'build/' . $m->{name} . '/usr/local/lib/perl5/lib',
        control_path => 'build/' . $m->{name} . '/DEBIAN/control',
        deb_name     => $m->{name} . '.deb',
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
    


sub meta_pm {
    #my $c = $control->($ARGV[0]);
    my $meta = $control->(@ARGV);
    p $meta;
    my $open = 'open_chrome_single_window.sh';
    my $deps_graph=system("$open $meta->{deps_graph} &2>1 /dev/null");
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
