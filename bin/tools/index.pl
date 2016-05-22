#!/usr/bin/env perl

use 5.010;
use warnings;
use strict;

use Encode;
use Data::Dumper;
use JSON;
use open qw<:encoding(UTF-8)>;

my $option = $ARGV[0] || print "\nUsage:\n\t - create index.json from html files \n\t\t'index.pl -j file1 file2 file#'" .
                                            "\n\n\t - create index.html from index.json (or $2) file \n\t\t'index.pl -h'\n\n";

my @tag_file = @ARGV;
shift @tag_file;

my $make_index = sub {
    my $tag_file = shift;
    my $index = {};

    for(@$tag_file){
        my $tag = $_;
        $tag =~ s/(.*?)(\..*)/$1/;
        $tag = $1;

        open(my $fh,"<",$_) || die "cant open $_: $!";
        $index->{$tag} = [];

        while(my $line = <$fh>){
            push $index->{$tag}, $line;
        };  close $fh;
    }
    $index = encode_json $index;
};

my $write_index = sub {
    my $file_type = shift;
    my $body = "test body";
    my $file = 'index.' . $file_type;
    my $index = {};

    if($file_type eq 'json'){
        $index = $make_index->(\@tag_file);
        #open(my $fh,">",$file) || die "cant open $file";
        #print $fh $index;
        print $index;
        #close $fh;
    }
    elsif( $file_type eq 'html' ){
        $file = $ARGV[1] || 'index.json';
        open(my $fh,"<",$file) || die "cant open $file";
        $index = <$fh>;
        $index = decode_json $index;

        for( @{$index->{head}} ){ print $_ }
        for( @{$index->{style}} ){ print $_ }
        for( @{$index->{body}} ){ print $_ }
        for( @{$index->{foot}} ){ print $_ }
    }
};


sub start {
    my $mode = shift;
    if($mode eq '-j'){ $write_index->('json') }
    if($mode eq '-h'){ $write_index->('html') }
}

start($option);
