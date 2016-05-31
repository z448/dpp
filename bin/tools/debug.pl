#!/usr/bin/env perl

#!/usr/bin/env perl

use 5.010;
use Encode;
use Data::Dumper;
use JSON;
use Cwd qw< abs_path >;
use open qw<:encoding(UTF-8)>;
use lib '.';
use Debug qw< control_json >;


my $control_json = control_json();
my $control_p5 = decode_json $control_json;
my @control = @$control_p5;

for my $field (@control){
    #print Dumper($_);
    for(keys %{$field}){
        print $field->{$_};
    }
}

#open(my $fh,">",'control.json') || die "cant open control.json: $!";
#print $fh $control_json;

__DATA__
use 5.010;
use Encode;
use Data::Dumper;
use JSON;
use Cwd qw< abs_path >;
use open qw<:encoding(UTF-8)>;
use lib '.';
use Debug qw< control_json >;

my $file_json = 'control.json';
my( $control ) = ();
my @control = ();

{
    open(my $fh,"<",$file_json) || die "cant open $file_json: $!";
    $control = <$fh>;
    $control = decode_json <$fh>;

    print $control->{name}  . "\n";
}


__DATA__

my $meta = {
    my $module = shift;
    my $metacpan = 'https://metacpan.org/pod/';
    my $meta_url = 'http://api.metacpan.org/v0/module/'."$module".'?join=release';
    my $meta_pod_url = 'http://api.metacpan.org/v0/pod/' . "$module" . '?content-type=text/plain';
    my $graph = 'https://widgets.stratopan.com/wheel?q=';
    my $meta_j = qx!curl -sL $meta_url!;
    my $meta_p = decode_json( encode( 'utf8', $meta_j ) );
    my $m = $meta_p->{release}->{_source};
    my $stratopan = $graph.$m->{name};
    my $prefix = 'lib';
    my $assets = "$ENV{DPP}/assets/html";
    my $deb_url = "deb/.stash/deb/" . $prefix . lc $m->{distribution} . '-p5' . '.deb';

    my $arch = sub { 
            my $arch;
            open my $pipe, '-|', 'uname -m';
            while(<$pipe>){
                if(/iPhone/){
                    $arch = 'iphoneos-arm';
                } else { $arch = 'all' }
            }
            return $arch;
    };


    my $remote = {
        cystash      => "$ENV{HOME}/.dpp/.stash",
        Name         => $m->{distribution},
        Version      => $m->{version},
        Author       => $m->{author},
        Section      => 'Perl',
        Description  => $m->{abstract},
        Depiction    => $graph.$m->{name},
        description  => $meta_p->{description},
        Homepage     => $metacpan . $meta_p->{module}[0]->{name},
        Maintainer   => 'zedbe (z448) <z448@module.pm>',
        install_path => $Config{installprivlib},
        module_name  => $meta_p->{module}[0]->{name},
        release_date => $meta_p->{date},
        Architecture => $arch->(),
        source_url   => $m->{download_url},
        deps_graph   => $graph.$m->{name},
        #   pod          => $meta_p->{pod},
        prefix       => 'lib',
        Package      => $prefix . lc $m->{distribution} . '-p5',
        pkg          => $prefix . lc $m->{distribution} . '-p5',
        build_path   => 'build/' . $m->{name} . '/usr/local/lib/perl5/lib',
        control_path => 'build/' . $m->{name} . '/DEBIAN/control',
        deb_name     => lc $m->{name} . '.deb',
        meta_api_url => $meta_url,
        Depends      => $deps->($module),
        www          => 'load.sh/cydia/index.html',
        div          => [ qq|<div class="dpp"><a href="$deb_url" target="_blank"><i class="fa fa-download" aria-hidden="true"></i> &nbsp;</a>|, qq|<a href="$stratopan" target="_blank"><i class="fa fa-asterisk" aria-hidden="true"></i>&nbsp;</a><a href="$meta_pod_url" target="_blank"><i class="fa fa-file" aria-hidden="true"></i></a></div>|, qq|<div class="module">$module</div>|, qq|<div class="description">$m->{abstract}</br></div>| ],
    };
    return $control;
};
__DATA__


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

