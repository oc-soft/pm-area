use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Area',
    VERSION_FROM =>  'lib/Area.pm',
    PL_FILES => {
        'tools/parser-gen.PL' => 'blib/lib/Area/PathParser.pm'
    }
);


# vi: se ts=4 sw=4 et:
