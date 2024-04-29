use strict;
use Test::Simple tests => 1;
use Area::Arc;

sub bounds {

    my $arc = Area::Arc->new(
        rx => 10,
        ry => 20,
        x1 => 5, y1 => 15,
        x2 => -5, y2 => -10,
        angle => 0,
        large_arc_flag => 0,
        sweep_flag => 0);

    my $bounds = $arc->bounds;

    my $test_res = $bounds->[0] <= -5;
    $test_res = $bounds->[1] <= -10 if $test_res;
    $test_res = $bounds->[2] >= 5 if $test_res;
    $test_res = $bounds->[3] >= 15 if $test_res;
    ok($test_res, 'expect bounds enclose x1, y1, x2, y2');
}


bounds;

# vi: se ts=4 sw=4 et:
