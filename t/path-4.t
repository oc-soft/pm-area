use strict;
use Area::Path;
use Test::Simple tests => 1;

sub clone {

    my $path = Area::Path->new;
    $path->moveto(1, 2);
    $path->lineto(2, 1);
    $path->cubic_bezierto(3, 4, 5, 6, 7, 8);
    $path->quadratic_bezierto(1, 2, 3, 4);
    $path->arcto(2, 1, 0, 0, 1, 3, 4);

    my @expected_commands = (
        'M 1 2',
        'L 2 1',
        'C 3 4 5 6 7 8',
        'Q 1 2 3 4',
        'A 2 1 0 0 1 3 4'
    );

    $path = $path->clone;

    my $test_res = 1;
    for (0 .. $path->command_count - 1) {
        $test_res = $path->command_str($_) eq $expected_commands[$_];
        last if !$test_res;
    }
    ok($test_res, 'expect clone succeeded');
}

clone;
# vi: se ts=4 sw=4 et:

