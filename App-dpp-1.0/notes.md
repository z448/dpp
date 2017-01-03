TODO
- fix symlinks "control.json + index.json" 
`cant open /var/root/dpp/assets/control.json: No such file or directory at /usr/local/lib/perl5/site_perl/5.22.0/App/Dpp.pm line 190, <$fh> chunk 5.`

LINKS
- [Debian Perl Group](https://pkg-perl.alioth.debian.org/)

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

