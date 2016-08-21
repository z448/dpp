package App::Dpp;

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

=head1 NAME

App::Dpp - make debian binary packages of perl modules

=cut

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( control meta web init cleanup );
}

our $VERSION = '1.0';

my $dpp = "$ENV{HOME}/dpp";
my $dir = {
    dpp             =>  $dpp,
    assets          =>  $dpp . '/' . 'assets',
    assets_html     =>  $dpp . '/' . 'assets' . '/' . 'html',
    build           =>  $dpp . '/' . 'build',
    stash           =>  $dpp . '/' . 'stash',
    deb             =>  $dpp . '/stash/deb',
};

my $cleanup = sub {
    my $dirty_dir = shift;
    system("chmod -R 0755 $dirty_dir");
    system("rm -r $dirty_dir");
    #rmdir $dirty_dir;
};


my $meta_api = sub {
    my $meta_url = shift;
    my $response = HTTP::Tiny->new->get("$meta_url");
    if($response->{success}){
        my $meta = $response->{content} if length $response->{content};
        $meta = decode_json $meta;
    } else {
        next;
        #die "http request failed";
    }
};

my $perl_version = sub {
    my $perl_version = $Config{PERL_REVISION} . '.' . $Config{PERL_VERSION} . '.' . $Config{PERL_SUBVERSION};
    #$perl_version = 'perl (>= ' . $perl_version . ')';
};

### init dpp direcories
my $init = sub {
    my $get = shift;
    
    # return dir PATH if param else create dirs and return \%dir
    if($get){
        return $dir->{$get};
    } else {
        mkpath $dpp;
        chmod( 0755, $dpp);
        for(keys %$dir){ mkpath $dir->{$_} }

        #symlink ~/.dpp/assets/index.json --> index.json
        my $index_link = init('assets') . "/index.json";

        #symlink ~/.dpp/assets/control.json --> control.json
        my $control_link = init('assets') . "/control.json";

        my $dpp_install_dir = abs_path($0);
        $dpp_install_dir =~ s/(.*)\/bin\/dpp$/$1/;
        $dpp_install_dir = $dpp_install_dir . '/' . 'lib/perl5/site_perl/' . $perl_version->() . '/App/Dpp';      

        my $index_file = $dpp_install_dir . '/' . 'index.json';
        chmod( 0644, $index_file);
        symlink $index_file, $index_link;

        my $control_file = $dpp_install_dir . '/' . 'control.json';
        chmod( 0644, $control_file);
        symlink $control_file, $control_link;

        return $dir;
    }
};
##-

### takes module name, returns hash ref with 2 hashes: $dep{control} and $dep{distribution}
my $deps = sub {
    my $pm = shift;
    my $core_pm = 

    ### takes module name; return distribution name
    my $dep_dis = sub {
        my $module_name = shift;
        my $meta_hash  = $meta_api->("http://api.metacpan.org/v0/module/$module_name?join=release"); 
        my $dist_dependencies = $meta_hash->{release}->{_source}->{distribution};
        return $dist_dependencies;
    };
    ##-

    ### takes module name returns array ref of module::name depandencies
    my $dep_pm = sub {
        my $module_name = shift;
        my $meta_hash  = $meta_api->("http://api.metacpan.org/v0/module/$module_name?join=release"); 
        my @module_dependencies = ();
        for( keys %{$meta_hash->{release}->{_source}->{metadata}->{prereqs}->{runtime}->{requires}} ){
            push @module_dependencies, $_ unless $Extensions{$_};
        }
        return \@module_dependencies;
    };
    ##- 

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

    # uniq
    my %dist_seen = ( );
    @dist_dep = grep { ! $dist_seen{$_} ++ } @dist_dep;

    for( @dist_dep ){
        unless( $_ eq 'perl' ){
            $dep{control} = $dep{control} . 'lib' . lc "$_" . "-p5220" . "\, ";
        } else { 
            next;
        }
    }
    #$dep{control} = $dep{control} . $perl_version->();
    $dep{control} = $dep{control} . 'sh.load.perl.5.22.0';
    return \%dep;
};
##-

my $meta = sub {
    my $module = shift;
    my $meta;
    my $metacpan = 'https://metacpan.org/pod/';
    my $meta_url = 'http://api.metacpan.org/v0/module/'."$module".'?join=release';
    my $meta_pod_url = 'http://api.metacpan.org/v0/pod/' . "$module" . '?content-type=text/plain';
    my $graph = 'https://widgets.stratopan.com/wheel?q=';
  
    $meta = $meta_api->( $meta_url );
    my $m = $meta->{release}->{_source};
    my $stratopan = $graph.$m->{name};
    my $prefix = 'lib';
    my $assets = $dir->{'assets'};
    my $deb_url = "http://load.sh/cydia/deb/" . $prefix . lc $m->{distribution} . '-p5220' . '.deb';

    ### if arch is iPhone use 'iphoneos-arm' string in control file otherwise use 'all'
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
    #-

    my $maintainer = sub {
        local $/;
        my $maintainer_file = init('assets') . '/' .   'control.json';
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
        Section      => 'perl',
        Description  => $m->{abstract},
#        Depiction    => $graph.$m->{name},
        description  => $meta->{description},
        Homepage     => $metacpan.$meta->{module}[0]->{name},
        Maintainer   => $maintainer->(),
        install_path => $Config{installprivlib},
        module_name  => $meta->{module}[0]->{name},
        release_date => $meta->{date},
        Architecture => $arch->(),
        source_url   => $m->{download_url},
        deps_graph   => $graph.$m->{name},
        prefix       => 'lib',
        Package      => $prefix . lc $m->{distribution} . '-p5220',
        pkg          => $prefix . lc $m->{distribution} . '-p5220',
        build_path   => 'build/' . $m->{name} . '/usr/local/lib/perl5/lib',
        control_path => 'build/' . $m->{name} . '/DEBIAN/control',
        deb_name     => lc $m->{name} . '.deb',
        meta_api_url => $meta_url,
        Depends      => $deps->($module),
        www          => 'load.sh/cydia/index.html',
        div          => [ qq|<div class="dpp"><a href="$deb_url" target="_blank"><i class="fa fa-download" aria-hidden="true">&nbsp;&nbsp;&nbsp;</i></a>|, qq|<a href="$stratopan" target="_blank"><i class="fa fa-asterisk" aria-hidden="true">&nbsp;&nbsp;&nbsp;</i></a><a href="$meta_pod_url" target="_blank"><i class="fa fa-file" aria-hidden="true">&nbsp;&nbsp;&nbsp;</i></a></div>|, qq|<div class="module">$module</div>|, qq|<div class="description">$m->{abstract}</br></div>| ],
        #div          => [ qq|<div class="dpp"><a href="$deb_url" target="_blank"><i class="fa fa-download" aria-hidden="true"></i> &nbsp;</a>|, qq|<a href="$stratopan" target="_blank"><i class="fa fa-asterisk" aria-hidden="true"></i>&nbsp;</a><a href="$meta_pod_url" target="_blank"><i class="fa fa-file" aria-hidden="true">&nbsp;</i></a></div>|, qq|<div class="module">$module</div>|, qq|<div class="description">$m->{abstract}</br></div>| ],
    };
    return $remote;
};

my $web = sub {
    my $pm = shift;
    my $index_json = $dir->{'assets'} . '/' . 'index.json';
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
    my @c = qw( Name Version Author Architecture Package Section Maintainer Homepage Description );
    #my @c = qw( Name Version Author Architecture Package Section Maintainer Homepage Depiction Description );
    
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


