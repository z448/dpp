use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::ssl4curl',
    AUTHOR           => q{Zdenek Bohunek <zed448@icloud.com>},
    VERSION_FROM     => 'lib/Debian/PerlPackager.pm',
    ABSTRACT_FROM    => 'lib/Debian/PerlPackager.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    'EXE_FILES'      => ['dpp', 'dbd'],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON::PP'          =>      '2.27300',
        'App::cpanminus'    =>      '1.7040',
        'Encode'            =>      '2.72',
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Debian-PerlPackager-1.0-*' },
);
