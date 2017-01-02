TODO
- on ios when building as root module folder (libperl-tidy-p5220) stays in root (/) directory. needs to be removed during packageing

- fix symlinks "control.json + index.json" `cant open /var/root/dpp/assets/control.json: No such file or directory at /usr/local/lib/perl5/site_perl/5.22.0/App/Dpp.pm line 190, <$fh> chunk 5.`

- exclude core modules from including into Depends field of control file except if it dependes on newer version

LINKS
- [Debian Perl Group](https://pkg-perl.alioth.debian.org/)
