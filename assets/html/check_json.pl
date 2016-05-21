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
    my $index = $json_file;
    push $index->{body}, \@body;
    open(my $fh,">",'./index.json') || die "cant open $json_file";
    print $fh encode_json $index;
    
    print "########in write#####\n" . Dumper( $index );

    return $index;
};

print "########before#####\n" . Dumper( $load->($index_json) );

print "########after#####\n" . Dumper( $write->( $load->($index_json) ) );

#print "########after#####\n" . Dumper( $load->($index_json) );

    
    


