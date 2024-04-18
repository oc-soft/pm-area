use strict;
use Test::Simple tests => 2; 
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


sub monotone_polygon_from_synmetric {

    my $poly = Area::Polygon->new(%{create_test_polygon_params_1;});


    my $indices = $poly->monotone_indices;

    ok(defined ($indices), 'expect poly is able to split monotone polygon.');
}

sub error_monotone {

    my $poly = Area::Polygon->new(%{create_test_polygon_params_2;});

    
    my $indices = $poly->monotone_indices;

    my $error = $poly->last_error;
    ok($error, 'expected poly can not split into monotone polygons.');
}

monotone_polygon_from_synmetric;
error_monotone; 
# vi: se ts=4 sw=4 et:
