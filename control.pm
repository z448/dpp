#!/usr/bin/env perl

use warnings;
use strict;
use feature 'say';
use JSON::Tiny qw(decode_json);

sub meta_req {
    my $meta_api_url='https://api.metacpan.org/v1/release/'."$ARGV[1]";
    my $meta_json=qx!curl -skL $meta_api_url!;
    my $meta_pm=decode_json $meta_json;
    #print $meta_json;
    return $meta_pm;
}

my $m=&meta_req;
say $m->{name}.' - '.$m->{abstract};
say 'Author: '.$m->{author};
say $m->{version};
say $m->{download_url};

say deps();

sub deps{
    say 'Deps:';
    for my $hash(@{$m->{dependency}}){
        if ($$hash{relationship} eq 'requires'){
            say $$hash{module};
        }
    }
}





#https://github.com/CPAN-API/cpan-api/wiki/API-Consumers



