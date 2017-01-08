package App::Dpp;

use 5.010;

use warnings;
use strict;

use HTTP::Tiny;
use Config;
use JSON::PP;
use Data::Dumper;
use File::Path;

=head1 NAME

App::Dpp - make debian binary packages of perl modules

=cut

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw( conf digest );
}


# get archname
my $arch = sub {
    open my $p, '-|', "dpkg --print-architecture";
    my $r = <$p>; chomp($r); close $p;
    if( $r ){ return $r }
    else { return $^O }
};

sub digest {
    my $file = shift;
    my( $data ) = ();
    open(my $fh,"<:raw :bytes",$file) || die "cant open $file: $!";
    while(<$fh>){ $data .= $_ }

    return  md5_hex($data);
};

my $meta_conf = sub {
    my $module = shift;
    #my( $module, $url ) = @_;
    my $url = 'http://api.metacpan.org/v0/module/'."$module".'?join=release';
	my $meta = '{}';
    my $response = HTTP::Tiny->new->get($url);
    #$response->{content} if length $response->{content};
    if($response->{success}){
        	$meta = $response->{content} if length $response->{content};
    } 
    return decode_json $meta;
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
         unless( core_module($_, $c->{perl}->{corepath}, $c->{arch}) ){
             my $m = $meta_conf->($_);
             $d{module} = $_; 
             $d{version} = $dep->{$_};
             $d{dist} = $m->{release}->{_source}->{distribution};
             push @depends,{%d};
         }
    }
    return \@depends;
};

# check if module is a core module
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
        my $maintainer = $name . ' ' . $email;
    }
}; 

sub control {
    my $c = shift;

    my $control = (
        Name    =>  $c->{module}->{name},
        Version =>  $c->{meta}->{version},
        Author  =>  $c->{meta}->{author},
        Architecture    =>  $c->{arch},
        Section =>  'perl',
        Maintainer  =>  $c->{maintainer},
        Homepage    =>  
    );
=head1
    my $dep = $m->{Depends};
    my @c = qw( Name Version Author Architecture Package Section Maintainer Homepage Description );
    
    my $c= '';
    for( @c ){
        $c = $c . $_.': '.$m->{$_}."\n";
    }
    $c = $c . 'Depends: ' . $dep->{control} . "\n";
    return $c;
=cut
}


sub conf {
    my( $module, $dpp_home ) = @_;
    $dpp_home = $dpp_home || "$ENV{HOME}/dpp";
    my $c;
    {
        local $/;
        $c = <DATA>;
    }
    # load DATA config
    eval $c;

    $c->{arch} = $arch->();
    $c->{module}->{name} = $module;
    
    # get meta conf from metacpan API
    $c->{meta} = $meta_conf->($module);
    
    # create dpp home dir
    my $dir = $c->{dir};
    for( keys %{$dir}){ mkpath( $dir->{$_} ) }

    if( $gitconfig->($c->{gitconfig}) ){
            $c->{maintainer} = $gitconfig->($c->{gitconfig});
    }

    # create default dpp.conf file if doesnt exist
    unless(-f $c->{conf_file}){
        open(my $fh,'>',$c->{conf_file}) || die "cant open $c->{conf_file}";
        for( qw< architecture package_prefix section maintainer > ){
            say $fh $_ . '=' . $c->{$_};
        }
        close $fh;
    }

    # read user conf from dpp.conf file
    my $u = $user_conf->("$c->{conf_file}");
    for( keys %{$u} ){
        $c->{$_} = $u->{$_} if defined $u->{$_} and exists $c->{$_};
    }

    # add core paths on darwin
    push @{$c->{perl}->{corepath}}, ( "installsitearch", "installsitelib" ) if $c->{arch} eq 'darwin';

    # create default .dump html conf
    unless( -f $c->{htmlconf}->{dump} ){
        open(my $fh,'>',$c->{htmlconf}->{dump}) || die "cant open $c->{htmlconf}->{dump}: $!";
        print $fh Data::Dumper->Dump([$c->{html}], ["html"]), $/;
        close $fh;
    }

    # module distribution name
    $c->{module}->{distribution} = $c->{meta}->{release}->{_source}->{distribution};

    # module non-core module dependencies
    $c->{module}->{depends} = $depends->( $c );


    return $c;
}

#print Dumper( conf($ARGV[0]) );
#conf($ARGV[0]);

__DATA__
$c = {
                  'package_prefix' => 'library',
                  'perl' => {
                        'corepath' => [
                            'installarchlib', 'installprivlib', 'installextrasarch', 'installextraslib', 'installupdatesarch', 'installupdateslib', 'installvendorarch', 'installvendorlib'
                        ],
                        'version' => "$Config{PERL_REVISION} . '.' . $Config{PERL_VERSION} . '.' . $Config{PERL_SUBVERSION}",
                   },
                  'gitconfig' => "$ENV{HOME}/.gitconfig",
                  'conf_file' => "$ENV{HOME}/dpp.conf",
                  'maintainer' => 'Your Name <your@email.com>',
                  'module' => {
                             'name' => '',
                           },
                  'htmlconf' => {
                             'dump' => "$dpp_home/.dump",
                             'html' => "$dpp_home/index.html",
                           },
                  'dir' => {
                             'dpp' => '/Users/zdenek/dpp',
                             'build' => '/Users/zdenek/dpp/build',
                             'deb' => '/Users/zdenek/dpp/deb'
                           },
                  'url' => 'http://api.metacpan.org/v0/module/'."$module".'?join=release',
                  'architecture' => 'all',
                  'section' => 'perl',
                  'html' => {
                          'body' => [
                                      '<div class="dpp"> </div>',
                                      '<div class="dpp"><a href="deb/' . "$module" . '" target="_blank"><i class="fa fa-download" aria-hidden="true"></i> &nbsp;</a>',
                                      '<a href="https://widgets.stratopan.com/wheel?q=HTTP-Tiny-0.058" target="_blank"><i class="fa fa-asterisk" aria-hidden="true"></i>&nbsp;</a><a href="http://api.metacpan.org/v0/pod/HTTP::Tiny?content-type=text/plain" target="_blank"><i class="fa fa-file" aria-hidden="true"></i></a></div>',
                                      '<div class="module">' . "$module" . '</div>',
                                      '<div class="description">A small, simple, correct HTTP/1.1 client</br></div>'
                                    ],
                          'foot' => [
                                      '<div class="footer" align="center" >dpp<br></div>',
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
                                      '<body bgcolor="#090311">',
                                      '<div align="center" >',
                                      '<div class="headtext"><br><br><sub>This is APT repository index.</sub><br><br></div>'
                                    ],
                          'style' => [
                                       '<style type="text/css"> ',
                                       '',
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
                                       '    background: #090311;',
                                       '}',
                                       '',
                                       '.dpp {',
                                       '    background: #090311;',
                                       '}',
                                       '',
                                       '.headtext {',
                                       '	font-family: \'Fira Mono\';',
                                       '	font-size: 11px;',
                                       '    text-align = "center";',
                                       '	background : #090311;',
                                       '    color: #8E8E8E;',
                                       '    top: 2px;',
                                       '    left: 0;',
                                       '    right: 0;',
                                       '}',
                                       '',
                                       '.description {',
                                       '	font-family: \'Fira Mono\';',
                                       '	font-size: 11px;',
                                       '    text-align = "center";',
                                       '	background : #090311;',
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
                                       '	font-size: 12px;',
                                       '	background : #090311;',
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
