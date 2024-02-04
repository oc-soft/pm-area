use strict;
use Test::Simple tests => 2;
use Area::Triangle;

my $triangle = Area::Triangle->new(
    x1 => 0 + 1,
    y1 => 0 + 1,
    x2 => 2 + 1,
    y2 => 0 + 1,
    x3 => 1 + 1,
    y3 => sqrt(3) + 1);

my $center = $triangle->center();


my @area = (
    $triangle->area(),
    2 * sqrt(3) / 2
);

my @expected_center = (
    1 + 1,
    sqrt(3) / 3 + 1 
);


ok(abs($area[1] - $area[0]) < 0.01,
    sprintf('expected triangle area(%f) is %f', $area[0], $area[1]));

ok(abs($center->{x} - $expected_center[0]) < 0.01
    && abs($center->{y} - $expected_center[1]) < 0.01,
    sprintf('expected center(%f, %f) is (%f, %f)', $center->{x}, $center->{y},
        $expected_center[0], $expected_center[1]));
# vi: se ts=4 sw=4 et:
