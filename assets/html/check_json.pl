#!/usr/bin/env perl
#
use 5.010;
use warnings;
use strict;

use JSON;
use Data::Dumper;
use open qw<:encoding(UTF-8)>;

my $index_json = './index.json';

my $load = sub {
    my $json_file = shift;
    open(my $fh,"<",$json_file) || die "cant open $json_file";
    my $index = <$fh>;
    $index = decode_json $index;
};

my $write = sub {
    my $json_file = shift;
    my @body = qw{ <div><a href="deb/package.deb">test_link</a></div> };
    #open(my $fh,">",$json_file) || die "cant open $json_file";
    my $index = $json_file;
    $index->{body} = \@body;
    print "########in write#####\n" . Dumper( $index );

    return $index;
};

print "########before#####\n" . Dumper( $load->($index_json) );

$write->( $load->($index_json) );

print "########after#####\n" . Dumper( $load->($index_json) );

    
    


