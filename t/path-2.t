use strict;

use Area::Path;
use Test::Simple tests => 3;
use Area::Path;

sub move_line_arc_close {

    my $path = Area::Path->new;

    $path->moveto(1, 0);

    $path->lineto(1, 1);
    $path->lineto(2, 1);
    $path->lineto(2, 2);
    $path->cubic_bezierto(2, 2.4, 1, 2,6, 0, 3);
    $path->lineto(0, 5);
    $path->lineto(-2, 5);
    $path->arcto(1, 1, 0, 0, 1, -2, 3);
    $path->close;

    my $poly_elems = $path->polygons_and_svg_elements;
    ok(@$poly_elems == 1, 'expected single polygon and svg_elemenents');
    
    my $polygon = $poly_elems->[0]->{polygon};
    my $svg_elements = $poly_elems->[0]->{svg_elements};
    ok($polygon, 'expect the path has a polygon');
    ok(@$svg_elements == 2, 'expect the path has to svg elements');
    
}

move_line_arc_close; 

# vi: se ts=4 sw=4 et:
