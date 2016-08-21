package App::Dpp::Packlist;

use warnings;
use strict;

use File::Find;
use Config;
use open qw<:encoding(UTF-8)>;

=head1 NAME

App::Dpp::Packlist

=cut

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( packages );

our $VERSION = '0.01';


my @packaged = ();

sub packaged {
    my $config = "$ENV{HOME}/dpp/.conf";

    open(my $fh,"<",$config) || die "cant open $config $!";
    while(<$fh>){
        chomp; push @packaged, $_;
    }
}


sub installed {
    my @packlist = ();
    my $path = "/usr/local/lib/perl5/site_perl";
    packaged();

    find(
            sub {
                my $path = "$File::Find::name";
                my %packlist = ();
                if ( $path =~ /\.packlist/) {
                    chomp($path);
                    $packlist{path} = "$path";

                    $packlist{module} = $packlist{path};
                    $packlist{module} =~ s/(auto.*?\/)(.*?)(\/\.packlist)/$2/;
                    $packlist{module} = $2;
                    $packlist{module} =~ s/\//\:\:/g;
                    $packlist{module} =~ s/\ //g;
                    $packlist{installed} = 1; 
                    $packlist{packaged} = grep { $packlist{module} eq $_ } @packaged;; 

                    push @packlist, {%packlist};
                }
            }
        , $path);
    return \@packlist;
}

sub packages {
    my $query = shift;
    my @result = ();
    if( $query eq 'installed'){
        for(@{installed()}){
            push @result, $_->{module} if $_->{installed};
        } 
    }
    if( $query eq 'packaged'){
        for(@{installed()}){
            push @result, $_->{module} if $_->{packaged};
        }
    }
    if( $query eq 'notpackaged'){
        for(@{installed()}){
            push @result, $_->{path} unless $_->{packaged};
        }
    }
    return \@result;
}

#packages($ARGV[0]);
1;

