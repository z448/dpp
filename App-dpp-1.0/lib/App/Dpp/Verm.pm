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
our @EXPORT_OK = qw< verm verl get >;
our $VERSION = '0.01';

sub z{
    my $color = shift;
    return sub { say colored([$color], caller ) . " " . shift if defined $ENV{app_dpp_debug} };
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
    my $url = shift;
    my $res;
    return sub{ $res = HTTP::Tiny->new->get("$url"); return $res->{content} }; 
    return sub{
       open my $p,'-|',"curl --user-agent \"Mozilla/5.0\" -skL '$url'";
       while( <$p> ){ $res .= $_ }
       return $res;
    };
};

# < module name > hash ref version => /path/to/version
my $version_path = sub {
    my $module = shift;

    my $res = $get->("https://metacpan.org/pod/$module");
    my $field = 0;
    my %version = ();
    my @m = ();

    my $z = z('magenta');
    $z->("Test:\$version_path");


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

=head2 verm

C<verm> 

Takes module name, returns hash ref: version => /path/to/version

=cut

sub verl {
    return $version_local->(shift);
}

sub verm {
    my $c = shift;
    my $cache = "$c->{dir}->{cache}/$c->{module}->{name}.verm"; # cache file
    my $z = z('cyan');

# dumper read
    my $data;
    my $versions;
    if( -f $cache ){
        $z->("verm(): cache file exist");
        open(my $fh,"<", $cache) || die "cant open $cache: $!";
        { local $/; $data = <$fh>; close $fh }
        eval $data;
        my $verl = verl($c->{module}->{name});
        my $contains_local = grep{ $_->{version} =~ /v?$verl$/ } @{$versions};
        return $versions if $contains_local;
    }
    $z->("verm():cache exist but has no local version");
        $versions = $version_path->("$c->{module}->{name}");
# dumper write
        open(my $fh,">", $cache) || die "cant open $cache:$!";
        print $fh Data::Dumper->Dump([$versions], ["versions"]), $/;
        close $fh;
        return $versions;
}

sub get {
    my $g = $get->(shift);
}

