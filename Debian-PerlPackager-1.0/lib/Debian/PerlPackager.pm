package Debian::PerlPackager;

use 5.010;
use warnings;
use strict;

use JSON;
use File::Copy;
use File::Path;
use Encode;
use Data::Dumper;
use Config;
use HTTP::Tiny;
use Config::Extensions qw( %Extensions );
use Cwd qw< abs_path >;
use open qw<:encoding(UTF-8)>;

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( control meta web init cleanup );
}


my $dpp = "$ENV{HOME}/.dpp";
my $dir = {
    dpp             =>  $dpp,
    assets          =>  $dpp . '/' . 'assets',
    assets_html     =>  $dpp . '/' . 'assets' . '/' . 'html',
    build           =>  $dpp . '/' . 'build',
    stash           =>  $dpp . '/' . '.stash',
    deb             =>  $dpp . '/.stash/deb',
    cpanm           =>  $dpp . '/' . 'build' . '/' . '.cpanm',
};

my $cleanup = sub {
    my $dirty_dir = shift;
    system("chmod -R 0755 $dirty_dir");
    system("rm -r $dirty_dir");
    #rmdir $dirty_dir;
};

my $perl_version = sub {
    my $perl_version = $Config{PERL_REVISION} . '.' . $Config{PERL_VERSION} . '.' . $Config{PERL_SUBVERSION};
    $perl_version = 'perl (= ' . $perl_version . ')';
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

        #symlink ~/.dpp/assets/html/index.json --> index.json
        my $index_link = init('assets') . "/index.json";

        #symlink ~/.dpp/assets/control.json --> control.json
        my $control_link = init('assets') . "/control.json";

        my $dpp_install_dir = abs_path($0);
        #my $index_file = abs_path($0);
        $dpp_install_dir =~ s/(.*)\/bin\/dpp/$1/;
        #$index_file =~ s/(.*)\/bin\/dpp/$1/;


        my $index_file = $dpp_install_dir . '/' . "lib/Debian/assets/index.json";
        #my $index_file = $dpp_install_dir . "/assets/html/index.json";
        symlink $index_file, $index_link;

        my $control_file = $dpp_install_dir . '/' . "lib/Debian/assets/control.json";
        symlink $control_file, $control_link;

        return $dir;
    }
};
# $init->();
# --

my $deps = sub {
    my $pm = shift;
    my $core_pm = 

    my $dep_dis = sub {
        my $m = shift;
        my $j = qx|curl -skL http://api.metacpan.org/v0/module/$m?join=release|;
        my $p  = decode_json( encode( 'utf8', $j )); 
        my $d = $p->{release}->{_source}->{distribution};
        return $d;
    };

    my $dep_pm = sub {
        my $m = shift;
        my $j = qx|curl -skL http://api.metacpan.org/v0/module/$m?join=release|;
        my $p  = decode_json( encode( 'utf8', $j )); 
        my @d;
        for( keys %{$p->{release}->{_source}->{metadata}->{prereqs}->{runtime}->{requires}} ){
            push @d, $_ unless $Extensions{$_};
        }
        return \@d;
    };

    my %dep;
    my @module_dep = ();
    my @dist_dep = ();
    $dep{control} = '';

    for ( @{$dep_pm->($pm)} ){
        push @module_dep, $_ unless $_ eq 'perl';
    }; $dep{module} = \@module_dep;

    for ( @{$dep_pm->($pm)} ){
        push @dist_dep, $dep_dis->($_) unless $_ eq 'perl';
    }
    $dep{distribution} = \@dist_dep;

    my %dist_seen = ( );
    @dist_dep = grep { ! $dist_seen{$_} ++ } @dist_dep;

    for( @dist_dep ){
        unless( $_ eq 'perl' ){
            $dep{control} = $dep{control} . 'lib' . lc "$_" . "-p5" . "\, ";
        } else { 
            next;
        }
    }
    $dep{control} = $dep{control} . $perl_version->();
    #$dep{control} = $dep{control} . "perl";
    return \%dep;
};

my $meta = sub {
    my $module = shift;
    my $meta_j;
    my $metacpan = 'https://metacpan.org/pod/';
    my $meta_url = 'http://api.metacpan.org/v0/module/'."$module".'?join=release';
    my $meta_pod_url = 'http://api.metacpan.org/v0/pod/' . "$module" . '?content-type=text/plain';
    my $graph = 'https://widgets.stratopan.com/wheel?q=';
    #  curl my $meta_j = qx!curl -sL $meta_url!;

    ### HTTP::Tiny
    my $response = HTTP::Tiny->new->get("$meta_url");
    if($response->{success}){
        $meta_j = $response->{content} if length $response->{content};
    } else {
        die "http request failed";
    }
    #-
                                     
    print $response->{content} if length $response->{content};
    #my $meta_j = qx!curl -sL $meta_url!;
    ## -


    my $meta_p = decode_json( $meta_j );
    #my $meta_p = decode_json( encode( 'utf8', $meta_j ) );
    my $m = $meta_p->{release}->{_source};
    my $stratopan = $graph.$m->{name};
    my $prefix = 'lib';
    #my $assets = "$ENV{DPP}/assets/html";
    my $assets = $dir->{'assets'};
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

    my $maintainer = sub {
        local $/;
        my $maintainer_file = init('assets') . '/' .  'control.json';
        print '## debug--> $maintainer_file' . "$maintainer_file" and die;
        open(my $fh, "<", $maintainer_file) || die "cant open $maintainer_file: $!"; 
            my $maintainer = <$fh>;
            $maintainer = decode_json $maintainer;
            return $maintainer->[0]->{Maintainer};
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
        Homepage     => $metacpan.$meta_p->{module}[0]->{name},
        Maintainer   => $maintainer->(),
        #Maintainer   => 'zedbe (z448) <z448@module.pm>',
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
    return $remote;
};

my $web = sub {
    my $pm = shift;
    my $index_json = $dir->{'assets'} . '/' . 'lib/Debian/index.json';
    my $m = $meta->( $pm );
    my ( @pipe, @body ) = ();
    my $index = {};

    # load indexsjson
    open(my $fh,"<", $index_json) || die "$index_json";
    $index = <$fh>;
    $index = decode_json $index;
    close $fh;
    
    # update index.json
    push @{$index->{body}}, @{$m->{ div }};
    
    #uniq body
    my %body_seen = ( );
    @body = grep { ! $body_seen{$_} ++ } @body;
    @{$index->{body}} = grep { ! $body_seen{$_} ++ } @{$index->{body}};

    open($fh,">",$index_json) || die "cant open $index_json: $!";
    print $fh encode_json $index;
    close $fh;
};

sub web {
    my $pm = shift;
    my $m = $web->($pm);
    return $m;
}

sub meta {
    my $pm = shift; 
    my $m = $meta->($pm);
}

sub control {
    my $pm  = shift;
    my $m = $meta->($pm);
    my $dep = $m->{Depends};
    my @c = qw( Name Version Author Architecture Package Section Maintainer Homepage Depiction Description );
    
    my $c= '';
    for( @c ){
        $c = $c . $_.': '.$m->{$_}."\n";
    }
    $c = $c . 'Depends: ' . $dep->{control} . "\n";
    return $c;
}

sub graph {
    my $pm = shift;
    my $gui = $meta->($pm);
    #my $open = 'osx_open_chome_sw.sh';
    my $deps_graph=qq|'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' --app="$gui->{deps_graph}" &2>1 /dev/null|;
    system("$deps_graph");
}

sub init {
    my $get = shift;
    my $init_status = $init->($get);
}

sub cleanup {
    my $dirty_dir = shift;
    #print '$cleanup->(' . $dirty_dir . ')';
    $cleanup->($dirty_dir);
};


