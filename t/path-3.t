use strict;
use Area::Path;
use Math::Trig ':pi';
use Test::Simple tests => 3;

sub translate {

    my $path = Area::Path->new;

    $path->moveto(10, 20);
    $path->lineto(20, 10);
    $path->cubic_bezierto(30, 40, 50, 60, 70, 80);
    $path->quadratic_bezierto(10, 20, 30, 40);
    $path->arcto(10, 20, 0, 0, 1, 30, 40);
    $path->translate(1, 1);

    my @expected_commands = (
        'M 11 21',
        'L 21 11',
        'C 31 41 51 61 71 81',
        'Q 11 21 31 41',
        'A 10 20 0 0 1 31 41'
    );

    my $test_res = 1;
    for (0 .. $#expected_commands) {
        $test_res = $path->command_str($_) eq $expected_commands[$_];
        last if !$test_res;
    }
     
    ok($test_res, 'expect the path moved to +(1, 1)');
}

sub scale {

    my $path = Area::Path->new;

    $path->moveto(1, 2);
    $path->lineto(2, 1);
    $path->cubic_bezierto(3, 4, 5, 6, 7, 8);
    $path->quadratic_bezierto(1, 2, 3, 4);
    $path->arcto(1, 2, 0, 0, 1, 3, 4);
    $path->scale(2, 3);

    my @expected_commands = (
        'M 2 6',
        'L 4 3',
        'C 6 12 10 18 14 24',
        'Q 2 6 6 12',
        'A 2 6 0 0 1 6 12'
    );

    my $test_res = 1;
    for (0 .. $#expected_commands) {
        $test_res = $path->command_str($_) eq $expected_commands[$_];
        last if !$test_res;
    }
     
    ok($test_res, 'expect the path scaled to (2, 3)');
}

sub rotate {

    my $path = Area::Path->new;

    $path->moveto(1, 2);
    $path->lineto(2, 1);
    $path->cubic_bezierto(3, 4, 5, 6, 7, 8);
    $path->quadratic_bezierto(1, 2, 3, 4);
    $path->arcto(2, 1, 0, 0, 1, 3, 4);
    $path->rotate(pip2);

    my @expected_commands = (
        'M -2 1',
        'L -1 2',
        'C -4 3 -6 5 -8 7',
        'Q -2 1 -4 3',
        'A 1 2 0 0 1 -4 3'
    );

    my $test_res = 1;
    for (0 .. $#expected_commands) {
        $test_res = $path->command_str($_) eq $expected_commands[$_];
        last if !$test_res;
    }
     
    ok($test_res, 'expect the path rotated 90 degrees');
}


translate;
scale;
rotate;

# vi: se ts=4 sw=4 et:
