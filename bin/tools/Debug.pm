package Debug;

use 5.010;
use warnings;
use strict;


use JSON;
use File::Copy;
use File::Path;
use Encode;
use Data::Dumper;
use Config;
use Config::Extensions qw( %Extensions );
use Cwd qw< abs_path >;
use open qw<:encoding(UTF-8)>;

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( control_json meta web init);
}


my %control = (
    Maintainer   => 'name (nick) <email>',
);

=head 

my $control = {
    Name         => '$m->{distribution}',
    Version      => '$m->{version}',
    Author       => '$m->{author}',
    Section      => 'Perl',
    Description  => '$m->{abstract}',
    Maintainer   => 'name (nick) <email>',
    Homepage     => '$metacpan . $meta_p->{module}[0]->{name}',
    Architecture => '$arch->()',
    Package      => '$prefix . lc $m->{distribution} . "-p5"',
    Depends      => '$deps->($module)',
};

=cut 

sub control_json {
    my @control = ();
    #push @control, $control;
    #return $control_p5;

    my $control_json = encode_json {%control};
    return $control_json;
}
