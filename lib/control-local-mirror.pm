#!/usr/bin/env perl
use MetaCPAN::Client;
use Data::Dumper;

# note
# add architecture (perl5/lib folder)A
#
my $m = MetaCPAN::Client->new();
my $module = $m->module('PAR::Packer');
my $release = $m->release('PAR-Packer');
my $pod = $m->pod('PAR::Packer')->html;

##debug dumps
#print $pm;
#print $pod;
#print Dumper $release;
#print Dumper $module;
my $d=$release->{data};
my $meta=$d->{metadata};

my @deps=$d->{dependency};
my $name_pm=$module->{data}{module};
my $package=$meta->{name};
my $version=$d->{version};
my $description=$meta->{abstract};
my $licence=$d->{licence};  # ???
my $author=$d->{author};
my $homepage='https://metacpan.org/pod/'.'';

my $src_url= $d->{download_url};

print "package:  $package"."\n"."version:  $version"."\n"."description:  $description"."\n"."\n"."author:  $author"."\n";
print "src url: $src_url"."\n";
print "module name:  "; for(@$name_pm){ print $_->{name} }; print "\n";
print "deps: "."\n";

for $dep (@deps){
    for $hash(@$dep){
            if ($$hash{phase} eq 'runtime' and $$hash{relationship} eq 'requires'){
                print "\t".$$hash{module}."\n";
                #print $key."\-\>".$value."\n"; 
            }
    }
}    
