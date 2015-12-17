#### debian manual
https://www.debian.org/doc/debian-policy/index.html#contents



use File::Copy;

copy("file1","file2");
copy("Copy.pm",\*STDOUT);'
move("/dev1/fileA","/dev2/fileB");

#find site_perl path
perl -e 'for(@INC){ if(/\/Sys/){print}}';

perl -e 'for(@INC){print $_."\n" if /Extras/}'



