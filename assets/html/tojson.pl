#!/usr/bin/env perl

use 5.010;
use Encode;
use Data::Dumper;
use JSON;
use open qw<:encoding(UTF-8)>;

my $head = './load.sh.head.txt';
my $foot = './load.sh.foot.txt';
my( $head_json, $foot_json ) = ();
my %html = ();
my $html;

{
    open($fh,"<",$head) || die "cant open $head: $!";
    local $/;
    $html{head} = <$fh>;
    #$head_json = encode_json \%html;
    close $fh;

    open($fh,"<",$foot) || "cant open $foot: $!";
    $html{foot} = <$fh>;
    $html = encode_json \%html;
}

open($fh,">",'./html.json') || die "cant open head.json: $!";
print $fh $html;
close $fh;


