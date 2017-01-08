package App::Dpp;

use 5.010;
use warnings;
use strict;

use JSON::PP;
use File::Copy;
use File::Path;
use Encode;
use Data::Dumper;
use Config;
use HTTP::Tiny;
use Digest::MD5 qw< md5_hex >;
use Config::Extensions '%Extensions';
use Cwd qw< abs_path >;
use open qw<:encoding(UTF-8)>;

use Term::ANSIColor;
=head1 NAME

App::Dpp - make debian binary packages of perl modules

=cut

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( control meta web init digest );
}

our $VERSION = '1.0';

sub digest {
    my $file = shift;
    my( $data ) = ();
    open(my $fh,"<:raw :bytes",$file) || die "cant open $file: $!";
    while(<$fh>){ $data .= $_ }

    return  md5_hex($data);
};

#my $dpp = "$env{home}/dpp";
#my $dir = {
#    dpp             =>  $dpp,
#    assets          =>  $dpp,
    #assets          =>  $dpp . '/' . 'assets',
    #assets_html     =>  $dpp . '/' . 'assets' . '/' . 'html',
#    build           =>  $dpp . '/' . 'build',
#    stash           =>  $dpp . '/' . 'stash',
#    deb             =>  $dpp . '/stash/deb',
#};


#my $cleanup = sub {
    #   my $dirty_dir = shift;
    #system("chmod -R 0755 $dirty_dir");
    #system("rm -r $dirty_dir");
    ##rmdir $dirty_dir;
#};


my $meta_api = sub {
    my $meta_url = shift;
    my $response = HTTP::Tiny->new->get("$meta_url");
    #$response->{content} if length $response->{content};

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
sub init {
    my $get = shift;
    my $dpp_home = "$ENV{HOME}/dpp";
    #my $dpp_home = ref $get eq 'HASH' ? $get->{dpp} : "$ENV{HOME}/dpp";

    my $dir = {
        dpp             =>  $dpp_home,
        deb             =>  $dpp_home . '/' . 'deb',
        build           =>  $dpp_home . '/' . 'build',
    };
    
    # return dir PATH if param is string else create dirs and return \%dir
    # if its a ref it passing getopts() (currently custom home for dpp)
    if($get){
        return $dir->{$get};
    } else {
        mkpath $dpp_home;
        chmod( 0755, $dpp_home);
        for(keys %$dir){ mkpath $dir->{$_} }

        unless(-f "$ENV{HOME}/dpp.conf"){
            my %config = (
                architecture    =>  'all',
                package_prefix  =>  'lib',
                section         =>  'perl',
                maintainer      =>  'Your Name <your@email.com>',
            );
            if(-f "$ENV{HOME}/.gitconfig"){
                open(my $fh,'<', "$ENV{HOME}/.gitconfig");
                my($name, $email, $user) = ();
                while(<$fh>){
                    chomp $_;
                    if(/\[.*\]/){ $user = 0 }
                    if(/\[user\]/){ $user = 1 }
                    if($user){
                        if(/name = (.*)/){ $name = $1 }
                        if(/email = (.*)/){ $email = $1 }
                    }
                }; 
                close $fh;
                $config{maintainer} = "$name <$email>";
            }

            open(my $fh,'>', "$ENV{HOME}/dpp.conf");
            for(keys %config){ print $fh "$_=$config{$_}\n" }
            close $fh;
        }

        unless( -f "$dir->{dpp}/index.json" ){
            my $index_data = <DATA>;
            my $index_file = $dir->{dpp} . '/' . 'index.json';
            #my $control_file = $dir->{dpp} . '/' . 'control.json';
            open(my $fh,'>',$index_file) || die "cant open $index_file: $!";
            print $fh $index_data; close $fh;
        }
        return $dir;
    }
};
##-


my $arch = arch();
my @install_path = qw< installarchlib installprivlib installextrasarch installextraslib installupdatesarch installupdateslib installvendorarch installvendorlib >;
my @osx_extra_path = qw< installsitearch installsitelib >;
push @install_path, @osx_extra_path if $arch eq 'darwin';

sub arch {
    open my $pipe,"-|",'uname -a';
    while(<$pipe>){
        if(/iPhone/){ return 'iphoneos-arm' }
        else { return $^O }
    }
}

sub core_module {
    my $module = shift;
    my %core_path = ();
    for( @install_path ){
        next unless defined $Config{$_};
        $core_path{$_} = $Config{$_} . '/' . "$module" . '.pm';
        $core_path{$_} = '/System' . $core_path{$_} if /installsite/;
        $core_path{$_} =~ s/::/\//g;
        return $core_path{$_} if -f $core_path{$_};
    }
}

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
                push @module_dependencies, $_ unless (core_module($_));
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
    $dep{control} = $dep{control} . 'perl';
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
    my $assets = init('dpp');
    #my $assets = $dir->{'assets'};
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
        my $maintainer_file = init('dpp') . '/' .   'control.json';
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

    my $init = init('dpp');
    my $index_json = $init->{dpp} . '/' . 'index.json';
    #my $index_json = $init->{dpp} . '/' . 'index.json';
    #my $index_json = $dir->{'assets'} . '/' . 'index.json';
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

#sub init {
#    my $get = shift;
#    my $init_status = $init->($get);
#}

#sub cleanup {
#   my $dirty_dir = shift;
#   #print '$cleanup->(' . $dirty_dir . ')';
#   $cleanup->($dirty_dir);
#};

__DATA__
{"body":["<div class=\"dpp\"> </div>\n","<div class=\"dpp\"><a href=\"deb/.stash/deb/libhttp-tiny-p5.deb\" target=\"_blank\"><i class=\"fa fa-download\" aria-hidden=\"true\"></i> &nbsp;</a>","<a href=\"https://widgets.stratopan.com/wheel?q=HTTP-Tiny-0.058\" target=\"_blank\"><i class=\"fa fa-asterisk\" aria-hidden=\"true\"></i>&nbsp;</a><a href=\"http://api.metacpan.org/v0/pod/HTTP::Tiny?content-type=text/plain\" target=\"_blank\"><i class=\"fa fa-file\" aria-hidden=\"true\"></i></a></div>","<div class=\"module\">HTTP::Tiny</div>","<div class=\"description\">A small, simple, correct HTTP/1.1 client</br></div>"],"foot":["<div class=\"footer\" align=\"center\" >dpp<br></div>\n","</body>\n","</html>\n"],"head":["<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n","<html xmlns=\"http://www.w3.org/1999/xhtml\">\n","<head>\n","<title>dpp</title>\n","<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n","<meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;\"/>\n","<meta name=\"apple-mobile-web-app-capable\" content=\"yes\" />\n","<meta name=\"apple-mobile-web-app-status-bar-style\" content=\"black-translucent\"/>\n","<script src=\"https://code.jquery.com/jquery-2.2.3.min.js\" integrity=\"sha256-a23g1Nt4dtEYOj7bR+vTu7+T8VP13humZFBJNIYoEJo=\" crossorigin=\"anonymous\"></script>\n","<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.6.3/css/font-awesome.min.css\" />\n","<link rel=\"stylesheet\" href=\"//code.cdn.mozilla.net/fonts/fira.css\">\n","<link rel=\"stylesheet\" href=\"//netdna.bootstrapcdn.com/bootswatch/3.3.0/paper/bootstrap.min.css\" />\n","<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">\n","</head>\n","\n","<body bgcolor=\"#090311\">\n","<div align=\"center\" >\n","<div class=\"headtext\"><br><br><sub>This is APT repository index.</sub><br><br></div>\n"],"style":["<style type=\"text/css\"> \n","\n",".slideshow-overlay {\n","    display: block;\n","    position: fixed;\n","    left: 0;\n","    top: 0;\n","    overflow: hidden;\n","    z-index: -99;\n","    height: 100%;\n","    width: 100%;\n","}\n","\n",".fa-download {\n","    background: #090311;\n","}\n","\n",".dpp {\n","    background: #090311;\n","}\n","\n",".headtext {\n","\tfont-family: 'Fira Mono';\n","\tfont-size: 11px;\n","    text-align = \"center\";\n","\tbackground : #090311;\n","    color: #8E8E8E;\n","    top: 2px;\n","    left: 0;\n","    right: 0;\n","}\n","\n",".description {\n","\tfont-family: 'Fira Mono';\n","\tfont-size: 11px;\n","    text-align = \"center\";\n","\tbackground : #090311;\n","    color: #4F4F50;\n","}\n","\n",".code{\n","    font-size: 10px;\n","    bottom: 5px;\n","\n","}\n","\n",".module {\n","    font-family: 'Open Sans', sans-serif;\n","    text-align = \"center\";\n","\tfont-size: 12px;\n","\tbackground : #090311;\n","\tcolor: #fefefe;\n","}\n","\n",".header{\n","\tfont-family: 'Fira Mono';\n","\tfont-size: 0;\n","\tcolor: white;\n","    -webkit-overflow-scrolling: touch;\n","    text-align: center;\n","    background: black;\n","    position: fixed;\n","    left: 0;\n","    right: 0;\n","    top: 0;\n","    height: 10px;\n","}    \n",".footer {\n","    font-family: 'Open Sans', sans-serif;\n","    font-weight: 600;\n","\tfont-size: 8px;\n","    border: 0;\n","    -webkit-overflow-scrolling: touch;\n","\tcolor: #4F4F50;\n","    text-align: center;\n","\tbackground : #1e1d20;\n","    position: fixed;\n","    left: 0;\n","    right: 0;\n","    bottom: 0;\n","    height: 13px;\n","}    \n","</style> \n"]}
{"body":[],"foot":["<div class=\"footer\" align=\"center\" >dpp<br></div>\n","</body>\n","</html>\n"],"head":["<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n","<html xmlns=\"http://www.w3.org/1999/xhtml\">\n","<head>\n","<title>dpp</title>\n","<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n","<meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;\"/>\n","<meta name=\"apple-mobile-web-app-capable\" content=\"yes\" />\n","<meta name=\"apple-mobile-web-app-status-bar-style\" content=\"black-translucent\"/>\n","<script src=\"https://code.jquery.com/jquery-2.2.3.min.js\" integrity=\"sha256-a23g1Nt4dtEYOj7bR+vTu7+T8VP13humZFBJNIYoEJo=\" crossorigin=\"anonymous\"></script>\n","<link rel=\"stylesheet\" href=\"https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.6.3/css/font-awesome.min.css\" />\n","<link rel=\"stylesheet\" href=\"//code.cdn.mozilla.net/fonts/fira.css\">\n","<link rel=\"stylesheet\" href=\"//netdna.bootstrapcdn.com/bootswatch/3.3.0/paper/bootstrap.min.css\" />\n","<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\">\n","</head>\n","\n","<body bgcolor=\"#090311\">\n","<div align=\"center\" >\n","<div class=\"headtext\"><br><br><sub>This is APT repository index.</sub><br><br></div>\n"],"style":["<style type=\"text/css\"> \n","\n",".slideshow-overlay {\n","    display: block;\n","    position: fixed;\n","    left: 0;\n","    top: 0;\n","    overflow: hidden;\n","    z-index: -99;\n","    height: 100%;\n","    width: 100%;\n","}\n","\n",".fa-download {\n","    background: #090311;\n","}\n","\n",".dpp {\n","    background: #090311;\n","}\n","\n",".headtext {\n","\tfont-family: 'Fira Mono';\n","\tfont-size: 11px;\n","    text-align = \"center\";\n","\tbackground : #090311;\n","    color: #8E8E8E;\n","    top: 2px;\n","    left: 0;\n","    right: 0;\n","}\n","\n",".description {\n","\tfont-family: 'Fira Mono';\n","\tfont-size: 11px;\n","    text-align = \"center\";\n","\tbackground : #090311;\n","    color: #4F4F50;\n","}\n","\n",".code{\n","    font-size: 10px;\n","    bottom: 5px;\n","\n","}\n","\n",".module {\n","    font-family: 'Open Sans', sans-serif;\n","    text-align = \"center\";\n","\tfont-size: 12px;\n","\tbackground : #090311;\n","\tcolor: #fefefe;\n","}\n","\n",".header{\n","\tfont-family: 'Fira Mono';\n","\tfont-size: 0;\n","\tcolor: white;\n","    -webkit-overflow-scrolling: touch;\n","    text-align: center;\n","    background: black;\n","    position: fixed;\n","    left: 0;\n","    right: 0;\n","    top: 0;\n","    height: 10px;\n","}    \n",".footer {\n","    font-family: 'Open Sans', sans-serif;\n","    font-weight: 600;\n","\tfont-size: 8px;\n","    border: 0;\n","    -webkit-overflow-scrolling: touch;\n","\tcolor: #4F4F50;\n","    text-align: center;\n","\tbackground : #1e1d20;\n","    position: fixed;\n","    left: 0;\n","    right: 0;\n","    bottom: 0;\n","    height: 13px;\n","}    \n","</style> \n"],"control":["architecture","maintainer","prefix-package","section"]}
