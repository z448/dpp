package App::Dpp::Verm;

use Term::ANSIColor;
use Data::Dumper;
use HTTP::Tiny;
use Config;

use 5.010;
use warnings;
use strict;

=head1 NAME

App::Verm - get path to specific version of module

=cut

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw< verm verl >;
our $VERSION = '0.01';

sub z{
    my $color = shift;
    return sub { say colored([$color], __PACKAGE__) . " " . shift if defined $ENV{app_dpp_debug} };
};


my $version_local = sub {
    my $module = shift;

    for my $path( qw< installsitelib installsitearch > ){
        $module =~ s/\:\:/\//g; 
        next unless -f "$Config{$path}/$module.pm";
        open(my $fh,'<',"$Config{$path}/$module.pm") || die "cant open: $!";
        while( <$fh> ){
            if(/(\:|\$)(VERSION)(.*?\=)(.*?)([0-9].*?)(\s|'|"|;)(.*)/){ return "$5" }
        }
    }
    return "$ARGV[0] module is not installed in $Config{installsitelib} or $Config{installsitearch}";
};

# < module name > use Tiny or curl to get content
my $get = sub {
    my %g = (
        url => 'https://metacpan.org/pod/',
        name => shift,
        agent => 'Mozilla/5.0',
    );

    my $res;
    return sub{ $res = HTTP::Tiny->new->get("$g{url}$g{name}"); return $res->{content} } if length $res->{content};
    return sub{
       open my $p,'-|',"curl --user-agent \"$g{agent}\" -skL '$g{url}$g{name}'";
       while( <$p> ){ $res .= $_ }
       return $res;
    };
};

# < module name > hash ref version => /path/to/version
my $version_path = sub {
    my $module = shift;
    my $res = $get->($module);
    my $field = 0;
    my %version = ();
    my @m = ();

    open(my $fh,'<',\$res->());
    while( <$fh> ){
        my %m = ();
        if(/Jump to version/){ $field = 1 }
        if( /(value|label)\=\"(.*?)\/(.*?)\/.*">(.*?)\ / ){
                return \%version if( $field == 1 and defined $version{"$4"});
                unless( $field == 0 or defined $version{"$4"} ){ 
                    $m{version} = $4;
                    $m{author} = $2;
                    $m{dist} = $3;
                    $m{path} = $m{author}; $m{path} =~ s/(.)(.)(.*)/$1\/$1$2/;
                    push @m, {%m};
                }
        }
        if(/\=\"\/pod\/release\/(.*?)\/(.*?)\/.*This version/){
            $m{author} = $1;
            $m{dist} = $2; 

            $m{dist} =~ /.*-(.*)/;
            $m{version} = $1;

            $m{path} = $m{author};
            $m{path} =~ s/(.)(.)(.*)/$1\/$1$2/;
            push @m, {%m};
        }
    }
    return \@m;
};



=head1 FUNCTIONS

=head2 verp

C<verp($module)> 

Takes module name, returns hash ref: version => /path/to/version

=cut

sub verl {
    return $version_local->(shift);
}

sub verm {
    my $c = shift;
    #my $c = {}; $c->{module}->{name} = "URI::Encode"; $c->{dir}->{cache} = "$ENV{HOME}/dpp/.cache";
    my $cache = "$c->{dir}->{cache}/$c->{module}->{name}.verm"; # cache file
    my $z = z('grey4');

# dumper read
    my $data;
    my $versions;
    if( -f $cache ){
        $z->("cache file exist");
        open(my $fh,"<", $cache) || die "cant open $cache: $!";
        { local $/; $data = <$fh>; close $fh }
        eval $data;
        my $verl = verl($c->{module}->{name});
        my $contains_local = grep{ $_->{version} =~ /v?$verl$/ } @{$versions};
        return $versions if $contains_local;
    }
        $z->("cache exist but has no local version");
        $versions = $version_path->($c->{module}->{name});
# dumper write
        open(my $fh,">", $cache) || die "cant open $cache:$!";
        print $fh Data::Dumper->Dump([$versions], ["versions"]), $/;
        close $fh;
        return $versions;
}












=head1 AUTHOR

Zdenek Bohunek, C<< <zdenek@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2017 Zdenek Bohunek, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

 

