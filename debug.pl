#!/usr/bin/env perl

use 5.010;
use Encode;
use Data::Dumper;
use JSON;
use File::Path qw< mkpath >;
use Cwd qw< abs_path >;
use Cydia::Meta qw< init >;
use open qw<:encoding(UTF-8)>;

my $link = init('assets_html') . "/index.json";
my $file = abs_path($0);
#$file =~ s/(.*)\/debug\.pl/$1/;
$file =~ s/(.*)\/index\.json/$1/;
print $file and die;

#symlink( init('assets_html') . "/index.json", "$ENV{HOME}/tmp/lala" );
symlink $file, $link;


__DATA__
print abs_path($0);
__DATA__
print init('dpp') . "/build/.cpanm";

__DATA__
#my $cwd = abs_path('.');
my $dpp = "$ENV{HOME}/.dpp";
#print $dpp and die;
my $dir = {
    build   =>  $dpp . '/' . 'build',
    stash   =>  $dpp . '/' . '.stash',
    deb     =>  $dpp . '/.stash/deb',
    cpanm   =>  $dpp . '/' . 'build' . '/' . '.cpanm',
};

# -  to init dpp direcories
my $init = sub {
    my $get = shift;
    
    # return dir PATH if param else create dirs and return \%dir
    if($get){
        return $dir->{$get};
    } else {
        mkpath $dpp;
        chmod( 0755, $dpp);
        for(keys %$dir){ mkpath $dir->{$_} }
        return $dir;
    }
}; print $init->();
# ---

