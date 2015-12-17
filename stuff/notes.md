**debian manual**
https://www.debian.org/doc/debian-policy/index.html#contents

**article**
http://cheeaun.com/blog/2012/03/how-i-built-hacker-news-mobile-web-app/

use File::Copy;

copy("file1","file2");
copy("Copy.pm",\*STDOUT);'
move("/dev1/fileA","/dev2/fileB");

**find site_perl path**
perl -e 'for(@INC){ if(/\/Sys/){print}}';

perl -e 'for(@INC){print $_."\n" if /Extras/}'

**using par lib**
use lib q!/var/mobile/Documents/pm2deb/lib/perl5!;
use PAR q!/var/mobile/Documents/pm2deb/lib/perl5/lib.par!;



