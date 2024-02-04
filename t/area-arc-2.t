use strict;
use Test::Simple tests => 4;
use Area::Arc;
use Math::Trig ':pi';



my $arc = Area::Arc->new(
    rx => 10, ry => 10,
    x1 => -10, y1 => 0,
    x2 => 10, y2 => 0,
    sweep_flag => 1);


my @triangles = (
    $arc->triangulation(pi / 100),
    $arc->triangulation(pi / 100, 1)
);

my @triangles_area = (0, 0);

while (my ($idx, $triangles_elms) = each @triangles) {
    for (@$triangles_elms) {
        $triangles_area[$idx] += $_->area();
    }
}

my $triangle_ave_area = 0;
for (@triangles_area) {
    $triangle_ave_area += $_;
}
$triangle_ave_area /= scalar(@triangles_area);

my $circle_area = pi * 10 ** 2 / 2; 

ok($circle_area > $triangles_area[0], 
    sprintf('check triangle area (%f) less than circle area (%f)',
        $triangles_area[0], $circle_area));


ok($circle_area < $triangles_area[1], 
    sprintf('check triangle area (%f) greater than circle area (%f)',
        $triangles_area[1], $circle_area));

my @differences;

push (@differences, abs($triangles_area[0] - $circle_area));
push (@differences, abs($triangles_area[1] - $circle_area));
push (@differences, abs($triangle_ave_area - $circle_area));

ok($differences[0] > $differences[2], 
    sprintf('check average diff (%f) less than small triangles diff(%f)',
        $differences[2], $differences[0]));

ok($differences[1] > $differences[2], 
    sprintf('check average diff (%f) less than large triangles diff(%f)',
        $differences[2], $differences[1]));


# vi: se ts=4 sw=4 et:
