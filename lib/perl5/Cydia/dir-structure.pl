!/usr/bin/env perl

 use IO::All;
 use JSON::Tiny;

 $io = io('.');
 print "$_\n" for $io->all_files(0); # this will get name of files for all installed files, deps included

 # use grep and dist name to filter out

 # if building w/ cpanm it'll make it's own list iof all installed files (.packlist)

 # first get name of distribution we're going to build from $ARGV[0]

 # use it to create/rename directory
 my $deb_name='p5'.$p5ver.$package_name;

 # have a path ready before running cpanm
 my $build_dir='build/$deb-name/usr/local/lib/perl5'

 # run cpanm (build/deb-name/usr/local/lib/perl5)
 cpanm -L $build_dir;

 # cpanm build creates additional 'lib/perl5' which needs to be renamed to 'site_perl/$p5ver' to make path as it woud be installed by root

 # final path after build is finished and dirs renamed (ex. running 5.14.4)
 build/p5-5.14.4-Plack/usr/local/lib/perl5/site_perl/5.14.4/Plack/-SomeStuff-/-arch-

 # run packager in 'build' dir pointing it to $deb-name used as name of final .deb


