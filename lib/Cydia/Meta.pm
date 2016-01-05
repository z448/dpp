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
    my $module = shift;
    my $metacpan = 'https://metacpan.org/pod/';
    my $meta_url = 'http://api.metacpan.org/v0/module/'."$module".'?join=release';
    my $meta_json = qx!curl -sL $meta_url!;
    my $meta = decode_json $meta_json;

    my $deps_line = sub {
        my $strings = shift;
        my @deps = ();
        for( keys %$strings ){ push @deps, $_.', ' }
        return \@deps;
    };

    my $c = {
        Name         => $meta->{release}->{_source}->{name},
        Version      => $meta->{release}->{_source}->{version},
        Author       => $meta->{release}->{_source}->{author},
        Description  => $meta->{release}->{_source}->{abstract}."\n".$meta->{description},
        Homepage     => $metacpan.$meta->{module}[0]->{name},
        Depends      => $deps_line->($meta->{release}->{_source}->{metadata}->{prereqs}->{runtime}->{requires}),
        module_name  => $meta->{module}[0]->{name},
        release_date => $meta->{date},
        source_url   => $meta->{release}->{_source}->{download_url},
        #pod         => $meta->{pod},
    };

    return $c;

};


    #
    # add & rw defaults from json here;
    #


my $paths = sub {
    my ($module, $prefix) = @_;
    my $c = $control->( $module );

    #my $dist = blib_to_par(); # make a PAR file using ./blib/
    #install_par($dist);       # install it into the system
    #uninstall_par($dist);     # uninstall it from the system
    #sign_par($dist);          # sign it using Module::Signature
    #verify_par($dist);        # verify it using Module::Signature

    #install_par("http://foo.com/DBI-1.37-MSWin32-5.8.0.par"); # works too
    #install_par("http://foo.com/DBI-1.37"); # auto-appends archname + perlver
    #install_par("cpan://SMUELLER/PAR-Packer-0.975"); # uses CPAN author directory

    my $pkg = {
        prefix => $prefix,
        name => $prefix . lc $$c{Name},
        package => $$c{Name},
        source_path => build_path => 'build/' . $$c{Name} . 'src',
        build_path => 'build/' . $$c{Name} . '/usr/local/lib/perl5/lib',
        control_path => 'build/' . $$c{Name} . '/DEBIAN/control',
        deb_name => $$c{Name} . 'deb',
    };

    my $get_source_pkg = qx!curl -sLo $$pkg{$source_path} $$c{$source_url}!;

    return $pkg;
};

my $build = sub {
    my ( $module ) = @_;
    my ( $source_url, $source_path ) = ( $control->()

sub meta_pm {
    my $c = $control->($ARGV[0]);
    p $control->($ARGV[0]);
    #for( keys %$c ){
    #    say $_.' -> '.$c->{ $_ };
    #}

    #print "Depends: ";
    #print @{$$c{Depends}};
    #print "\n";
    p $paths->( @ARGV );
}

meta_pm();

