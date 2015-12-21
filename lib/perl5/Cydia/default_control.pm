#!/usr/bin/env perl
use JSON::PP;
use open qw< :encoding(UTF-8) >;
use Getopt::Std;
use Data::Dumper;

my $conf_json = "";
my $fh = undef;
getopts('f:', \%opts);

sub get_conf {
    my $conf;
    local $/ = undef;

    unless($opts{'f'}){   # ---take json from -f otion and return hash of array
        $conf = <DATA>;
        close $fh;
        return decode_json $conf;

    } else {   # --- if no -f on input, take data from DATA
        open($fh, "<", $opts{'f'})||die "$0:can't open file $!";
        $conf = <$fh>;
        close $fh;
        return decode_json $conf;
    }
}

my $conf = get_conf();
print Dumper($conf);

# Default init data, containing control file field, value-of-field, id and optional 0/1

__DATA__
[{"field":"Architecture","optional":0,"value":"","id":"architecture"},{"id":"maintainer","field":"Maintainer","optional":0,"value":""},{"value":"","optional":1,"field":"Homepage","id":"homepage"},{"id":"priotity","field":      "Priority","optional":1,"value":""},{"id":"priotity","optional":1,"field":"Priority","value":""},{"id":"depiction","value":"","optional":1,"field":"Depiction"},{"id":"description","value":"","optional":0,"field":               "Description"},{"id":"name","value":"","field":"Name","optional":0},{"id":"package","value":"","optional":0,"field":"Package"},{"id":"version","value":"","optional":0,"field":"Version"},{"field":"Depends","optional":1,"value": "","id":"depends"},{"id":"author","field":"Author","optional":0,"value":""}]
 ~
 ~
