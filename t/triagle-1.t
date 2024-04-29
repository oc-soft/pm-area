use strict;
use Test::Simple tests => 1;
use Area::Triangle;


sub bounds {
    my $triangle = Area::Triangle->new (
        x1 => -1, y1 => 1,
        x2 => 3, y2 => 6,
        x3 => -10, y3 => -20
    );
    my @expect = (-10, -20, 3, 6);
    my $bounds = $triangle->bounds;

    my $test_res = 1; 
    for (0 .. $#expect) {
        $test_res = $bounds->[$_] == $expect[$_];
        last if !$test_res;
    }
    ok($test_res, 'expect calculate bounds correctly');
}


bounds;

# vi: se ts=4 sw=4 et:
