#!/usr/bin/env perl

use 5.010;
use warnings;
use strict;

use Encode;
use Data::Dumper;
use JSON;
use open qw<:encoding(UTF-8)>;

my $head_file = './head.html';
my $foot_file = './foot.html';
my $body_file = './body.html';
my $css_file = './style.css';
my @tag_file = ( $head_file, $foot_file, $body_file, $css_file );

my $make_index = sub {
    my $tag_file = shift;
    my $index = {};

    for(@$tag_file){
        my $tag = $_;
        $tag =~ s/(\.\/)(.*?)(\..*)/$2/;
        print $tag . "\n";

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
        open(my $fh,">",$file) || "cant open $file";
        print $fh $index;
        close $fh;
    }
    elsif( $file_type eq 'html' ){
        $file = 'index.json';
        open(my $fh,"<",$file) || "cant open $file";
        $index = <$fh>;
        $index = decode_json $index;

        for( @{$index->{head}} ){ print $_ }
        for( @{$index->{style}} ){ print $_ }
        for( @{$index->{body}} ){ print $_ }
        for( @{$index->{foot}} ){ print $_ }

        # for(keys %$index){
        #    for my $line ( @{$index->{$_}} ){
        #            print $line;
        #    }
        #}
    }
};

#$write_index->('json');
$write_index->('html');

__DATA__
        $file = 'index.json';
        open(my $fh,"<",$file) || die "cant open $file: $!";
        $index = <$fh>:
        $index = decode_json $index;
        $body = $m->{div};

};

