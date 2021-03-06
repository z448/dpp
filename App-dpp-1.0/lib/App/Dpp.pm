package App::Dpp;

use 5.010;

use Sys::Hostname;
use Term::ANSIColor;
use Digest::MD5 qw< md5_hex >;
use HTTP::Tiny;
use Config;
use JSON::PP;
use Data::Dumper;
use File::Path;
use App::Dpp::Verm qw< verm verl get >;

use warnings;
use strict;

=head1 NAME

App::Dpp - make debian binary packages of perl modules

=cut

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( conf digest debug );
}

my $dpp_home = "$ENV{HOME}/dpp";
my %initialized = (); 


# get name email from gitconfig if exist
my $gitconfig = sub {
    my $config = shift;
    if( -f $config ){
        my($name, $email, $user) = ();
        open(my $fh,'<', $config);
        while( <$fh> ){
            chomp;
            if( /\[.*\]/ ){ $user = 0 }
            if( /\[user\]/ ){ $user = 1 }
            if( $user ){
                if( /name = (.*)/ ){ $name = $1 }
                if( /email = (.*)/ ){ $email = $1 }
            }
        }; 
        close $fh;
        my $maintainer = $name . ' ' . "<$email>";
    }
}; 

my $d;
{ local $/; $d = <DATA>; close DATA }

# create ~/.dpp config if doesnt exist and set dpp_home
unless(-f "$ENV{HOME}/.dpp"){
    my %init = (
        dpp_home        =>  "$ENV{HOME}/dpp",
        pkgid  =>  hostname,
        maintainer      =>  'Your Name <name@email.com>',
    );
    # get name/email from gitconfig if exist
    $init{maintainer} = $gitconfig->("$ENV{HOME}/.gitconfig") if $gitconfig->("$ENV{HOME}/.gitconfig");
    open(my $CONF,'>',"$ENV{HOME}/.dpp") || die "cant open $ENV{HOME}/.dpp: $!";
    print $CONF "$_=$init{$_}\n" for keys %init;
    close $CONF;
}

# get index.html from remote server if defined in ~/.dpp
my $index = sub {
    my $c = shift;
    say "running \$index->()";
    unlink("$c->{dir}->{dpp}/index.html");

    if( defined $c->{repository} ){
        my $html = get("http://$c->{repository}/index.html");
        open(my $fh,'>', "$c->{dir}->{dpp}/index.html");
        print $fh $html->() if length $html;
        close $fh;
    } else { 
        open(my $fh,'>',"$c->{dir}->{dpp}/index.html") || die "cant open $c->{dir}->{dpp}/index.html:$!";
        say $fh $_ for @{$c->{html}->{head}};
        say $fh $_ for @{$c->{html}->{style}};
        close $fh;
    }
    $initialized{index} = "$c->{dir}->{dpp}/index.html";
};

# read ~/.dpp conf file and get $dpp_home;
open(my $CONF,'<',"$ENV{HOME}/.dpp") || die "cant open $ENV{HOME}/.dpp: $!";
while( <$CONF> ){
    if(/(^dpp_home)(\=)(.*)/){ $dpp_home=$3; chomp $dpp_home }
}
close $CONF;

sub init {
    return $dpp_home;
}

# architecture
my $arch = sub {
    open my $p, '-|', "dpkg --print-architecture";
    my $r = <$p>; chomp($r); close $p;
    if( $r ){ return $r }
    else { return $^O }
};

sub digest {
    my $file = shift;
    my $data = 0;
    #my( $data ) = ();
    open(my $fh,"<:raw :bytes",$file) || die "cant open $file: $!";
    while(<$fh>){ $data .= $_ }

    return md5_hex($data);
};

my $meta_conf = sub {
    my( $path, $c )  = @_;
    my $cache = $path; $cache =~ s/\//-/g;
    $cache = "$c->{dir}->{cache}/$cache";

    if( -f $cache ){ 
        open(my $fh,'<',$cache) || die "cant open $cache:$!";
        local $/; my $res = <$fh>; close $fh; 
        return decode_json $res;
    } else {
        my $url = "https://fastapi.metacpan.org/v1/module/$path?join=release";
        my $res = HTTP::Tiny->new->get($url);
        my $j = decode_json $res->{content};
        open(my $fh,'>',$cache) || die "cant open $cache:$!";
        print $fh $res->{content}; close $fh;
        return $j;
    }
};

my $user_conf = sub {
    my $conf_file = shift;
    my %user_conf = ();

    open(my $fh,'<',"$conf_file") || die "cant open $conf_file: $!";
    while( <$fh> ){
        s/(.*?)(\=)(.*)/$1$3/;
        $user_conf{$1} = "$3";
    }
    return \%user_conf;
};

# module dependencies
my $depends = sub {
    my $c = shift;
    my( @depends, %d) = ();
    my $dep = $c->{meta}->{release}->{_source}->{metadata}->{prereqs}->{runtime}->{requires};
    for( keys %{$dep} ){
        # unless( $_ eq 'perl' ){
        unless( $_ eq 'perl' or core_module($_, $c->{perl}->{corepath}, $c->{arch}) ){
             my $m = $meta_conf->($_, $c); # assumeing dist name is same for older version
             $d{module} = $_; 
             $d{version} = $dep->{$_};
             $d{dist} = $m->{release}->{_source}->{distribution};
             $d{package} = 'lib' . lc $m->{release}->{_source}->{distribution} . "-perl"; 
             #$d{package} = 'lib' . lc $m->{release}->{_source}->{distribution} . "-perl$c->{perl}->{version}.$c->{perl}->{subversion}-" . lc $c->{pkgid}; 
             $d{package} =~ s/\./\-/g;
             push @depends,{%d} unless $d{dist} eq 'perl';
         }
    }
    return \@depends;
};

# check if module is already installed in non site path
sub core_module {
    my( $module, $corepaths, $arch ) = @_;
    my( %core_path ) = ();
    for( @{$corepaths} ){
        next unless defined $Config{$_};
        $core_path{$_} = $Config{$_} . '/' . "$module" . '.pm';
        $core_path{$_} = '/System' . $core_path{$_} if $arch eq 'darwin';
        $core_path{$_} =~ s/::/\//g;
        return $core_path{$_} if -f $core_path{$_};
    }
}

my $control = sub {
    my $c = shift;
    my $perl_dep = "perl (>= $c->{perl}->{version}.$c->{perl}->{subversion}), perl (<< $c->{perl}->{version}.".(int($c->{perl}->{subversion}) +1) .")";
    my $module_version = $c->{module}->{version}; $module_version =~ s/[A-Za-z]//g;

    my $depends = sub {
        my $deps = $c->{module}->{depends};
        my $d = $perl_dep;
        for( @{$deps} ){
            $_->{version} =~ s/[A-Za-z]//g;
            $d .= ', ' . "$_->{package} (>= $_->{version})";
        }
        return $d;
    };

    my %control = (
        Name    =>  $c->{module}->{name},
        Package =>  $c->{module}->{package},
        Version =>  $module_version,
        Author  =>  $c->{meta}->{author},
        Architecture    =>  $c->{arch},
        Section =>  'perl',
        Maintainer  =>  $c->{maintainer},
        Homepage    => $c->{module}->{homepage},
        Description => $c->{meta}->{release}->{_source}->{abstract},
        Depends => $depends->(),
    );
    $control{Depends} = $control{Depends} . 'perl-modules-' . 
    return \%control;
};

sub conf {
    my $module = shift;
    my $dpp_home = init();

    # load DATA config
    my $c = {};
    my $distribution;
    eval $d;

    $c->{arch} = $arch->();
    $c->{module}->{name} = $module;
    
    print $module;
    # create dpp dirs
    my $dir = $c->{dir};
    for( keys %{$dir}){ mkpath( $dir->{$_} ) }

    $c->{pkgid} = hostname;

    # read .dpp conf file
    my $u = $user_conf->("$ENV{HOME}/.dpp");
    for( keys %{$u} ){
        $c->{$_} = $u->{$_} if defined $u->{$_};
        #$c->{$_} = $u->{$_} if defined $u->{$_} and exists $c->{$_};
    }

# create head style for index.html
    $index->($c) unless $initialized{index};
    #$index->($c) unless exists $initialized{index};
    #}

    # add core paths on osx
    #push @{$c->{perl}->{corepath}}, ( "installsitearch", "installsitelib" ) if $c->{arch} eq 'darwin';

    # get meta conf from metacpan API
    $c->{meta} = $meta_conf->($module,$c);
    my $latest_ver = $c->{meta}->{version}; $latest_ver =~ s/[a-zA-Z]//g;
    print "--------$latest_ver---------\n";
    my $local_ver = verl($c->{module}->{name});
    $c->{module}->{version} = $c->{meta}->{version};
    $c->{module}->{distribution} = $c->{meta}->{release}->{_source}->{distribution};
    $c->{module}->{homepage} = "https://metacpan.org/release/$c->{module}->{distribution}";

    unless( $latest_ver eq $local_ver ){
           my $meta_ver = verm($c);
           my( $m ) = grep{ $_->{version} =~ /.?$local_ver$/ } @{$meta_ver};
           $c->{meta} = {};
           $c->{module}->{homepage} = "https://metacpan.org/release/$m->{author}/$m->{dist}";
           $c->{meta} = $meta_conf->("$m->{author}/$m->{dist}", $c);
           $c->{module}->{version} = $c->{meta}->{version}; # set version to meta version which might have different format
       } 

    # main module
    $c->{module}->{main} = $c->{meta}->{release}->{_source}->{main_module};
    # module distribution name
    $c->{module}->{distribution} = $c->{meta}->{release}->{_source}->{distribution};
    # module description
    $c->{module}->{description} = $c->{meta}->{release}->{_source}->{abstract};
    # module package name
    $c->{module}->{package} = 'lib' . lc $c->{module}->{distribution} . '-perl';
    #$c->{module}->{package} = 'lib' . lc $c->{module}->{distribution} . '-perl' . "$c->{perl}->{version}-$c->{perl}->{subversion}-" . lc $c->{pkgid};
    $c->{module}->{package} =~ s/\./\-/g;
    # module .deb file name
    $c->{module}->{debfile} = 'lib'.lc $c->{module}->{distribution}."$c->{module}->{version}-$c->{arch}".'-perl'."$c->{perl}->{version}.$c->{perl}->{subversion}-" . lc $c->{pkgid}.'.deb';
    # module non-core module dependencies
    $c->{module}->{depends} = $depends->($c);
    # control file
    $c->{module}->{control} = $control->($c);
    # create html body
    my $b = $c->{html}->{body};
    $c->{html}->{body} = $b->($c->{module});

    return $c;
}

__DATA__
$c = {
                  'pkgid' => '',
                  #'repository' => '',
                  'perl' => {
                        'corepath' => [
                            'installvendorarch', 'installvendorlib', 'installprivlib', 'installarchlib'
                            #'installarchlib', 'installprivlib', 'installextrasarch', 'installextraslib', 'installupdatesarch', 'installupdateslib', 'installvendorarch', 'installvendorlib'
                        ],
                        'version' => "$Config{PERL_REVISION}" . '.' . "$Config{PERL_VERSION}",
                        'subversion' => "$Config{PERL_SUBVERSION}",
                   },
                  'config' => "$ENV{HOME}/.dpp",
                  'maintainer' => 'Your Name <your@email.com>',
                  'module' => {
                             'name' => '',
                           },
                  'htmlconf' => {
                             'conf' => "$dpp_home" . '/.index',
                             'html' => "$dpp_home/index.html",
                           },
                  'dir' => {
                             'dpp' => "$dpp_home",
                             'build' => "$dpp_home/.build",
                             'deb' => "$dpp_home/deb",
                             'cache' => "$dpp_home/.cache",
                           },
                  'url' => 'http://fastapi.metacpan.org/v1/module/'."$module".'?join=release',
                  'html' => {
                               'body' => sub{  
                                        my $c = shift;
                                        my $b = '<div class="dpp"> </div>'.
                                        '<div class="module">' . "$module" . '</div>'.
                                        '<div class="dpp"><a href="deb/'. $c->{debfile} . '" target="_blank"><i class="fa fa-download" aria-hidden="true"></i> &nbsp; &nbsp; &nbsp;</a><a href="https://widgets.stratopan.com/wheel?q='. $c->{distribution} .'-'. $c->{version} .
                                      '" target="_blank"><i class="fa fa-asterisk" aria-hidden="true"></i> &nbsp; &nbsp; &nbsp;</a><a href="http://fastapi.metacpan.org/v1/pod/'."$module".'?content-type=text/plain" target="_blank"><i class="fa fa-file" aria-hidden="true"></i></a></div>'.
                                      '<div class="description">' . $c->{description}.
                                      '</br></br></div>';
                                      return $b;
                              },
                          'foot' => [
                          #'<div class="footer" align="center" >dpp<br></div>',
                                      '</body>',
                                      '</html>'
                                    ],
                          'head' => [
                                      '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
                                      '<html xmlns="http://www.w3.org/1999/xhtml">',
                                      '<head>',
                                      '<title>dpp</title>',
                                      '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />',
                                      '<meta name="viewport" content="width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;"/>',
                                      '<meta name="apple-mobile-web-app-capable" content="yes" />',
                                      '<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"/>',
                                      '<script src="https://code.jquery.com/jquery-2.2.3.min.js" integrity="sha256-a23g1Nt4dtEYOj7bR+vTu7+T8VP13humZFBJNIYoEJo=" crossorigin="anonymous"></script>',
                                      '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.6.3/css/font-awesome.min.css" />',
                                      '<link rel="stylesheet" href="//code.cdn.mozilla.net/fonts/fira.css">',
                                      '<link rel="stylesheet" href="//netdna.bootstrapcdn.com/bootswatch/3.3.0/paper/bootstrap.min.css" />',
                                      '<link rel="stylesheet" type="text/css" href="style.css">',
                                      '</head>',
                                      '',
                                      '<body bgcolor="#090811">',
                                      '<div align="center" >',
                                      '<div class="headtext"><br><br><sub>This is APT repository index.</sub><br><br></div>',
                                      '<div class="footer" align="center" >dpp<br></div>',
                                    ],
                          'style' => [
                                       '<style type="text/css"> ',
                                       '',
                                       '.fa-download {',
                                       'color: #4F4F50;',
                                       '}',
                                       '.fa-asterisk {',
                                       'color: #4F4F50;',
                                       '}',
                                       '.fa-file {',
                                       'color: #4F4F50;',
                                       '}',
                                       '.slideshow-overlay {',
                                       '    display: block;',
                                       '    position: fixed;',
                                       '    left: 0;',
                                       '    top: 0;',
                                       '    overflow: hidden;',
                                       '    z-index: -99;',
                                       '    height: 100%;',
                                       '    width: 100%;',
                                       '}',
                                       '',
                                       '.fa-download {',
                                       '    background: #090811;',
                                       '}',
                                       '',
                                       '.dpp {',
                                       '    background: #090811;',
                                       '	line-height: 110%;',
                                       '}',
                                       '',
                                       '.headtext {',
                                       '	font-family: \'Fira Mono\';',
                                       '	font-size: 11px;',
                                       '    text-align = "center";',
                                       '	background : #090811;',
                                       '    color: #8E8E8E;',
                                       '    top: 2px;',
                                       '    left: 0;',
                                       '    right: 0;',
                                       '}',
                                       '',
                                       '.description {',
                                       '	font-family: \'Fira Mono\';',
                                       '	font-size: 11px;',
                                       '	line-height: 110%;',
                                       '    text-align = "center";',
                                       '	background : #090811;',
                                       '    color: #4F4F50;',
                                       '}',
                                       '',
                                       '.code{',
                                       '    font-size: 10px;',
                                       '    bottom: 5px;',
                                       '',
                                       '}',
                                       '',
                                       '.module {',
                                       '    font-family: \'Open Sans\', sans-serif;',
                                       '    text-align = "center";',
                                       '	font-size: 13px;',
                                       '	background : #090811;',
                                       '	color: #fefefe;',
                                       '}',
                                       '',
                                       '.header{',
                                       '	font-family: \'Fira Mono\';',
                                       '	font-size: 0;',
                                       '	color: white;',
                                       '    -webkit-overflow-scrolling: touch;',
                                       '    text-align: center;',
                                       '    background: black;',
                                       '    position: fixed;',
                                       '    left: 0;',
                                       '    right: 0;',
                                       '    top: 0;',
                                       '    height: 10px;',
                                       '}    ',
                                       '.footer {',
                                       '    font-family: \'Open Sans\', sans-serif;',
                                       '    font-weight: 600;',
                                       '	font-size: 8px;',
                                       '    border: 0;',
                                       '    -webkit-overflow-scrolling: touch;',
                                       '	color: #4F4F50;',
                                       '    text-align: center;',
                                       '	background : #1e1d20;',
                                       '    position: fixed;',
                                       '    left: 0;',
                                       '    right: 0;',
                                       '    bottom: 0;',
                                       '    height: 13px;',
                                       '}    ',
                                       '</style> '
                                     ]
                        }
            };
