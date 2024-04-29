use strict;
use Test::Simple tests => 1;
use Area::Polygon;

sub bounds {
    my %param = (
        p0 => [ -1, -1 ],
        p1 => [ 3, 4 ],
        p2 => [ 10, 30 ]
    );

    my $polygon = Area::Polygon->new(%param);

    my $bounds = $polygon->bounds;
    my @expect = ( -1, -1, 10, 30 );
    my $test_res = 1;
    for (0 .. $#expect) {
        $test_res = $bounds->[$_] == $expect[$_];
        last if !$test_res;
    }
    ok($test_res, 'expect calculate polygon bounds correctly');
}


bounds;

# vi: se ts=4 sw=4 et:
