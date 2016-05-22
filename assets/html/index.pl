#!/usr/bin/env perl

use 5.010;
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
        # $tag =~ s/(\.\/)(....)(\.html)/$2/;
        $tag =~ s/(\.\/)(.*?)(\..*)/$2/;
        print $tag . "\n";

        open($fh,"<",$_) || die "cant open $_: $!";
        $index->{$tag} = [];

        while(my $line = <$fh>){
            push $index->{$tag}, $line;
        };  close $fh;
    }
    $index = encode_json $index;
};

my $write_index = sub {
    my $file_type = shift;
    my $file = 'index-test.' . $file_type;
    my $index = {};

    if($file_type eq 'json'){
        $index = $make_index->(\@tag_file);
        open($fh,">",$file) || "cant open $file";
        print $fh $index;
    }
};

$write_index->('json');




#    open($fh,"<",$foot_file) || "cant open $foot_file: $!";
#    $index{foot} = <$fh>;
#    $index = encode_json \%html;
#}

#open($fh,">",'./html.json') || die "cant open head.json: $!";
#print $fh $index;
#close $fh;


