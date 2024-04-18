use strict;
use Test::Simple tests => 4; 
use Math::Trig qw(:pi);
use Area::Polygon;


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


sub create_test_polygon_params_2 {
    my @points = (
        [0, 0],
        [1, 1],
        [-1, 2], 
        [1, 3],
        [0, 4],
        [-1, 3],
        [1, 2],
        [-1, 1] 
    );
    my %poly_args;
    for (0 .. $#points) {
        $poly_args{"p$_"} = $points[$_];
    } 
    \%poly_args;
}

sub create_test_polygon_params_3 {
    my @points = (
        [0, 0],
        [1, 1],
        [1.5, 2], 
        [1, 3],
        [0, 3.5],
        [-1, 3],
        [-1.5, 2],
        [-1, 1] 
    );
    my %poly_args;
    for (0 .. $#points) {
        $poly_args{"p$_"} = $points[$_];
    } 
    \%poly_args;
}


sub find_rotation {

    my $poly = Area::Polygon->new(%{create_test_polygon_params_1;});

    my $rotation = $poly->calculate_rotation(
        test_count => 2,
        rotation_division => 4);

    ok(!defined $rotation, 'expect failed to find rotation');

    $rotation = $poly->calculate_rotation;
    
    ok(defined $rotation, 'expect to find rotation');
}

sub find_intersection {

    my $poly = Area::Polygon->new(%{create_test_polygon_params_2;});

    my $intersections = $poly->find_intersections_unsafe; 

    my @intersec_keys = keys %$intersections; 
    
    ok(scalar(@intersec_keys) == 2, 'expect to get two intersections');

    $poly = Area::Polygon->new(%{create_test_polygon_params_3;});
    $intersections = $poly->find_intersections_unsafe; 
    @intersec_keys = keys %$intersections;

    ok(scalar(@intersec_keys) == 0, 'expect to get no intersection');
}

find_rotation;
find_intersection; 
# vi: se ts=4 sw=4 et:
