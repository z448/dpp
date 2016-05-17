package Cydia::Meta;

use 5.010;
use warnings;
use strict;

use JSON;
use File::Copy;
use Encode;
use Data::Dumper;
use Config;
use Config::Extensions qw( %Extensions );
use open qw<:encoding(UTF-8)>;

BEGIN {
    require Exporter;
    our $VERSION = 0.01;
    our @ISA = qw(Exporter);
    our @EXPORT = qw( control meta graph web dep path );
}


#for( keys {grep( /Storable/, keys %Extensions)}){
#print "$_"."\n";
#}'

### !!! finish orig; find right paths for each platform
### perl -V + ExtUtils::MakeMaker to find out; 

my $path = sub {
    my $q = shift;
    my $post = {
    original    =>  [ "./usr/local/lib/perl5/site_perl", "./usr/local/lib/perl5/lib/5.14.4", "./usr/local/bin" ],
    build       =>  [ "./usr/local/lib/perl5/lib", "./usr/local/lib/perl5/lib/perl5", "./usr/local/lib/perl5/bin" ],
    }; 

    my $pre = {
    original    =>  [ "./usr/xxxxxxxxxxxerl5/site_perl", "./usr/xxxxxxxxxxperl5/lib/5.14.4" ],
    build       =>  [ "./usr/xxxxxxxxxxperl5/lib", "./usr/xxxxxxxxxxxxxx5/lib/perl5" ],
    }; 

    return unless $q;
    if( $q eq 'post' ){
        return $post } 
    elsif ( $q eq 'pre' ){ return $pre }

};

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

my %seen = ( );
my @deps_uniq = grep { ! $seen{$_} ++ } @dist_dep;

    for( @deps_uniq ){
        unless( $_ eq 'perl' ){
            $dep{control} = $dep{control} . 'lib' . lc "$_" . "-p5" . "\, ";
        } else { 
            next;
        }
    }
    $dep{control} = $dep{control} . "perl";
    # (>= 5.14.4)";
    return \%dep;
};


my $meta = sub {
    my $module = shift;
    my $metacpan = 'https://metacpan.org/pod/';
    my $meta_url = 'http://api.metacpan.org/v0/module/'."$module".'?join=release';
    my $graph = 'https://widgets.stratopan.com/wheel?q=';
    my $meta_j = qx!curl -sL $meta_url!;
#    print $meta_j;
    my $meta_p = decode_json( encode( 'utf8', $meta_j ) );
    my $m = $meta_p->{release}->{_source};
    my $stratopan = $graph.$m->{name};
    my $prefix = 'lib';
    my $assets = "$ENV{DPP}/assets/html";
     
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
        Maintainer   => 'zedbe (z448) <z448@module.pm>',
        install_path => $Config{installprivlib},
        module_name  => $meta_p->{module}[0]->{name},
        release_date => $meta_p->{date},
        Architecture => 'all', #'iphoneos-arm', #$Config{archname}
        source_url   => $m->{download_url},
        deps_graph   => $graph.$m->{name}, #Moose-2.1205
        pod          => $meta_p->{pod},
        prefix       => 'lib',
        Package      => $prefix . lc $m->{distribution} . '-p5',
        pkg          => $prefix . lc $m->{distribution} . '-p5',
        build_path   => 'build/' . $m->{name} . '/usr/local/lib/perl5/lib',
        control_path => 'build/' . $m->{name} . '/DEBIAN/control',
        deb_name     => lc $m->{name} . '.deb',
        meta_api_url => $meta_url,
        Depends      => $deps->($module),
        www          => 'load.sh/cydia/index.html',
    #    div          => [ qq|\n\t<div class="module"><a href="$stratopan">&#10036;<\a></div>|, qq|\n\t<div class="module">$module</div>|, qq|\t<div class="description">$m->{abstract}</br></br></div>| ],
         div          => [ qq|\n\t<div class="link"><a href="deb/| . lc $m->{name} . q|.deb| . qq| "><img border="0" alt="download" src="$assets/download.png" width="100" height="100"></a><br><div>|, qq|\n\t<div class="module">$module</div>|, qq|\t<div class="description">$m->{abstract}</br></div>| ],
    };
    return $remote;
};

my $web = sub {
    my $pm = shift;
    my $m = $meta->( $pm );
    my ($html, @pipe, @body) = ();

    # load header/footer
    {
        open(my $fh,"<","$ENV{DPP}/assets/html/html.json") || die "$ENV{DPP}/assets/html/html.json $!";
        $html = <$fh>;
        $html = decode_json $html;
        close $fh;
    }

    # append current module div to div.html
    {
        open( my $fh, '>>', "$ENV{DPP}/assets/html/div.html") || die "cant open: $!";
        say   $fh @{$m->{ div }};
        close $fh;
    }

    # load div.html to @body
    {
        open(my $fh,"<","$ENV{DPP}/assets/html/div.html") || die "cant open: www.html";
        while(<$fh>){
            push @body, $_ if /module/ or /description/;
        };
    }
    
    # load http:// body to @body
    {
        open my $pipe, '-|', "curl -# $m->{ www }"; 
        while(<$pipe>){
            push @body, $_ if /module/ or /description/;
        }; 
    }
    
    my %body_seen = ( );
    @body = grep { ! $body_seen{$_} ++ } @body;
    $html->{ body } = \@body;

    open( my $fh, '>', "$ENV{DPP}/assets/html/index.html") || die "cant open: $!";
    print $fh $html->{ head };   
    say   $fh @{$html->{ body }};
    print $fh $html->{ foot };
    close $fh;
};

sub web {
    my $pm = shift;
    my $m = $web->($pm);
    return $m;
}
    
sub meta {
    my $pm = shift; my $m = $meta->($pm);
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

sub path {
    my $stage = shift;
    my $p = $path->( $stage );
    return $p;
}


__DATA__


