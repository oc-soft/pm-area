use strict;

use Test::Simple tests => 4;
use Math::Trig ':pi';
use Area::Polygon;

sub compare_number_arrays {
    my ($array_0, $array_1) = @_;
    
    my $len_0 = scalar @$array_0;
    my $len_1 = scalar @$array_1;
    my $comp_len = $len_0 < $len_1 ? $len_0 : $len_1;
    my $res = 0;
    for (0 .. $comp_len - 1) {
        $res = $array_0->[$_] <=> $array_1->[$_];
        last if $res;
    }
    if ($res == 0) {
        $res = $len_0 <=> $len_1;
    }
    $res;
}

sub compare_number_arrays_arrays {
    my ($num_arrays_0, $num_arrays_1) = @_;
    my $len_0 = scalar @$num_arrays_0;
    my $len_1 = scalar @$num_arrays_1;
    my $comp_len = $len_0 < $len_1 ? $len_0 : $len_1;
    my $res = 0;
    for (0 .. $comp_len - 1) {
        $res = compare_number_arrays $num_arrays_0->[$_], $num_arrays_1->[$_];
        last if $res;
    }
    if ($res == 0) {
        $res = $len_0 <=> $len_1;
    }
    $res;
}
 
sub create_test_polygon_params_1 {
    my @points = (
        [ 1, 0 ],
        [ cos (pi / 6), sin (pi / 6) ],
        [ cos (pi / 4), sin (pi / 4) ],
        [ cos (pi / 3), sin (pi / 3) ],
        [ 0, 1 ],
        [ cos ((pi * 2) / 3), sin ((pi * 2) / 3) ],
        [ cos ((pi * 3) / 4), sin ((pi * 3) / 4) ],
        [ cos ((pi * 5) / 6), sin ((pi * 5) / 6) ],
        [ -1, 0 ],
        [ cos ((pi * 7) / 6), sin ((pi * 7) / 6) ],
        [ cos ((pi * 5) / 4), sin ((pi * 5) / 4) ],
        [ cos ((pi * 4) / 3), sin ((pi * 4) / 3) ],
        [ 0, -1 ],
        [ cos ((pi * 5) / 3), sin ((pi * 5) / 3) ],
        [ cos ((pi * 7) / 4), sin ((pi * 7) / 4) ],
        [ cos ((pi * 11) / 6), sin ((pi * 11) / 6) ]
    );
    my %poly_args;
    for (0 .. $#points) {
        $poly_args{'p' . $_} = $points[$_];
    }
    \%poly_args;
}


sub symmetric_polygon_1 {
    my $poly = Area::Polygon->new(%{ create_test_polygon_params_1; });

    my $indices = $poly->monotone_triangulation_indices; 

    my @expected = (
        [ 0, 1, 2 ],
        [ 3, 2, 0 ],
        [ 0, 3, 4 ],
        [ 15, 0, 4 ],
        [ 14, 15, 4 ],
        [ 13, 14, 4 ],
        [ 5, 4, 13 ],
        [ 13, 5, 6 ],
        [ 12, 13, 6 ],
        [ 7, 6, 12 ],
        [ 12, 7, 8 ],
        [ 11, 12, 8 ],
        [ 10, 11, 8 ],
        [ 9, 8, 10 ]);

    my $test_res = compare_number_arrays_arrays(\@expected, $indices); 
    ok($test_res == 0, 'symmetric polygon have to be triangulated.');
}


sub symmetric_polygon_2 {
    my $poly = Area::Polygon->new(%{ create_test_polygon_params_1; });

    my $indices = $poly->monotone_mountain_triangulation_indices; 

    my @expected = (
        [ 0, 1, 2 ],
        [ 0, 2, 3 ],
        [ 0, 3, 4 ],
        [ 15, 0, 4 ],
        [ 14, 15, 4 ],
        [ 13, 14, 4 ],
        [ 5, 4, 13 ],
        [ 13, 5, 6 ],
        [ 12, 13, 6 ],
        [ 6, 7, 12 ],
        [ 12, 7, 8 ],
        [ 11, 12, 8 ],
        [ 10, 11, 8 ],
        [ 9, 8, 10 ]);

    my $test_res = compare_number_arrays_arrays(\@expected, $indices); 
    ok($test_res == 0, 'symmetric polygon have to be triangulated.');
}

sub symmetric_polygon_3 {
    my $poly = Area::Polygon->new(
        p0 => [1, 0],
        p1 => [0, 1],
        p2 => [-1, 0],
        p3 => [0, -1]);

    my $indices = $poly->monotone_triangulation_indices; 
    my @expected = (
        [ 1, 0, 3 ],
        [ 2, 3, 1 ]);

    my $test_res = compare_number_arrays_arrays(\@expected, $indices); 
    ok($test_res == 0, 'symmetric polygon have to be triangulated.');
}

sub symmetric_polygon_4 {
    my $poly = Area::Polygon->new(
        p0 => [1, 0],
        p1 => [0, 1],
        p2 => [-1, 0],
        p3 => [0, -1]);

    my $indices = $poly->monotone_mountain_triangulation_indices; 
    my @expected = (
        [ 0, 1, 3 ],
        [ 1, 2, 3 ]);

    my $test_res = compare_number_arrays_arrays(\@expected, $indices); 
    ok($test_res == 0, 'symmetric polygon have to be triangulated.');
}
  

symmetric_polygon_1;
symmetric_polygon_2;
symmetric_polygon_3;
symmetric_polygon_4;

# vi: se ts=4 sw=4 et:
