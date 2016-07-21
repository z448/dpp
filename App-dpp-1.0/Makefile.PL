use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::dpp',
    AUTHOR           => q{Zdenek Bohunek <zed448@icloud.com>},
    VERSION_FROM     => 'lib/App/Dpp.pm',
    ABSTRACT_FROM    => 'lib/App/Dpp.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    'EXE_FILES'      => ['dpp'],
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON::PP'          =>      '2.27300',
        'Encode'            =>      '2.72',
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-dpp-1.0-*' },
);
