package App::Dpp::VersionPath;

use Data::Dumper;
use HTTP::Tiny;

use 5.010;
use warnings;
use strict;

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( version_path );
}

my $get = sub {
    my $name = shift;
    my %g = (
        url => 'https://metacpan.org/pod/',
        name => $name,
        agent => 'Mozilla/5.0',
    );

    my $res;
    return sub{ $res = HTTP::Tiny->new->get("$g{url}$g{name}"); return $res->{content} } if defined $res;
    return sub{
       open my $p,'-|',"curl --user-agent \"$g{agent}\" -skL '$g{url}$g{name}'";
       while( <$p> ){ $res .= $_ }
       return $res;
    };
};

my $version_path = sub {
    my $module = shift;
    my $res = $get->($module);
    my $field = 0;
    my %version = ();

    open(my $fh,'<',\$res->());
    while( <$fh> ){
        if(/Jump to version/){ $field = 1 }
        if( /(value|label)\=\"(.*?)\/(.*?)\/.*">(.*?)\ / ){
                return \%version if( $field == 1 and defined $version{"$4"});
                unless( $field == 0 or defined $version{"$4"} ){ $version{"$4"} = "$2/$3" }
        }
    }
    return \%version;
};

sub version_path {
    my( $module,  $version ) = @_;
    my $p = $version_path->($module);
    return $p->{$version};
}
1;
