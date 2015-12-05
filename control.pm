#!/usr/bin/env perl

package control;

use strict;
use warnings;
use feature 'say';
use JSON::Tiny qw(decode_json);


BEGIN {
    require Exporter;
    our $VERSION = 1.00;
    our @ISA = qw(Exporter);
    our @EXPORT = qw($control get_control);
}

our $control = '';
my $dist = '';
my $meta_api_url = '';
my $meta_json = '';
my $meta = '';

my $control_conf = sub { 
    my $c_json = open(my $fh, "<", "control.conf") or die "cannot open < control.conf: $!";
    my $c_conf = decode_json $c_json;
    return $c_conf;
};

my $get_control = sub {
    $dist=shift;
    $meta_api_url='https://api.metacpan.org/v0/release/'."$dist";
    $meta_json=qx!curl -skL $meta_api_url!;
    $meta=decode_json $meta_json;
    return $meta;
};

sub get_control {
    $dist = shift;
    $control = $get_control->($dist);
    return $control;
}

1;
