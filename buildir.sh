#!/bin/bash

rm -rf local
"ln" -s lib/perl5/Cydia/Deb.pm ::
rm -rf build
mkdir -p build/usr/local/lib/perl5/site_perl
mkdir build/DEBIAN
touch build/DEBIAN/control
