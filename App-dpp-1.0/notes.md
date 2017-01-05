TODO

- generate Packages.gz into dpp_home
- make sure custom dpp_home is in/above users home dir
- add -p for tar compress to preserve permissions and change first tar/untar method
- fix symlinks "control.json + index.json" 
`cant open /var/root/dpp/assets/control.json: No such file or directory at /usr/local/lib/perl5/site_perl/5.22.0/App/Dpp.pm line 190, <$fh> chunk 5.`

- cpan on ubuntu under root user doesnt install packlists; not posible to get packlist from Metacpan API as non .pm files created after build are not included; Therefore for root get module path and create own packlist including all files under module path in installsitelib + installarchlib; cpan under non root user is ok, it include packlists but such .deb package would include local username (/home/zdenek)

- add architectore check on debian using command `dpkg --print-architecture`;
```
~/tmp/mydir uname -a
Linux load.sh 3.13.0-24-generic #47-Ubuntu SMP Fri May 2 23:30:00 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
~/tmp/mydir dpkg --print-architecture
amd64
```

LINKS
- [Debian Perl Group](https://pkg-perl.alioth.debian.org/)
- [stackoverflow](http://stackoverflow.com/questions/4564434/why-does-my-hand-created-deb-package-fails-at-install-with-unable-to-create-on)

DONE
- exclude core modules from including into Depends field of control file except if it dependes on newer version

```perl
=head1
            ### cant use this code because Config::Extensions doesnt seems to work; for example it finds List::Util but it doesn't find Scalar::Util which are both part of perl core libraries (Scalar-List-Utils distribution)

            if( $Extensions{$_} ){
                say colored(['red'],"NOT adding $_ because $Extensions{$_} is in core");
            } else { 
                push @module_dependencies, $_;
                say colored(['yellow'],"adding $_ because $Extensions{$_} is NOT in core");
            }
=cut
```

