#!/usr/bin/env perl

use IO::All;
use JSON::XS; #do it fast
use List::MoreUtils qw/ uniq /;
use Term::ANSIColor;

my @lines = io('etc/02packages.details.txt')->slurp; # slurp file to array
my (@pkgs, %pkg, $opt);

$opt=$ARGV[0]; 
#$opt=qr/$opt/;

sub splitit { # split lines by whitespace
    for my $line (@lines) {
        @pkg = split(' ', $line );
            my $word = $pkg[2]; #take only last bit
            push @pkgs, $word;
    }
}

sub unique {
    my @unique = uniq @pkgs; #copy unique 
    for (@unique) {
        s/.*\/(.*)\-.*?\.tar\.gz/$1/; $_=$1; #strip leading path, remove suffix
#        s/\-/\ /g; # dash to \s
        $pkg{'t'} = $_;
        push @p, {%pkg}; #hash ref to array
        }
}

sub jay { #to json
    my $p = \@p;
    my $j = encode_json $p;
    $j > io('minicpan.json');
    #print $j;
    srch(\$p);
}
splitit(); unique(); jay();

sub srch {
    if (defined($opt) && ($opt =~ /.*/)) {
            my @match = grep { $_->{'t'} =~ /.?$opt.?/ } @p;
            print `clear`;
            print "meta"; print colored(qq!\ \:\:\ !, q!red on_bright_black!); print "cpan\n";

    for (@match) {
        if ($i % 2) {
            print colored(qq!$_->{'t'}!, q!white on_bright_black!);
        } else {
            print colored(qq!$_->{'t'}!, q!white on_bright_black!);
        }
        #print colored(qq!\ \:\ !, q!white on_bright_black!);
        print colored(qq!\ \:\:\ !, q!red on_bright_black!);
        $i++;
    }
    #print colored(qq!\n\n>>Use!, q!on_bright_black!);
    #print colored(qq! -i !, q!white on_bright_black!);
    #print colored(qq!as a second parameter to build and install module!, q!on_bright_black!);
    print "\n";
    }
}