
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME                => 'DreamGuild',
    AUTHOR              => q{Onur Aslan <onuraslan@gmail.com>},
    VERSION_FROM        => 'lib/DreamGuild/WWW.pm',
    ABSTRACT            => 'Dream Guild Web Site',
    LICENSE             => 'MIT',
    PL_FILES            => { 'script/dreamguild' => '--create-db' },
    PREREQ_PM => {
        'Mojolicious'     => 5,
        'ORLite'          => 0,
        'LWP::UserAgent'  => 0,
        'Digest::SHA'     => 0,
        'JSON::XS'        => 0,
        'File::Path'      => 0,
        'XML::Parser'     => 0
    },
    EXE_FILES           => [ 'script/dreamguild', 'script/dreamguild-www' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DreamGuild-*' },
);
