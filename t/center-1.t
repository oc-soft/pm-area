use strict;
use feature qw(isa);
use Test::Simple tests => 4;
use Area::PathParser;

sub create_round_rect_param {
    my ($offset_x, $offset_y) = @_;
    $offset_x = 0 if !defined $offset_x;
    $offset_y = 0 if !defined $offset_y;

    my @path_params = (
        [ 'M', [ 0.5, 0 ] ],
        [ 'L', [ 2.5, 0 ] ],
        [ 'A', [ .5, .5, 0, 0, 1 ], [ 3, 0.5 ] ], 
        [ 'L', [ 3, 1.5] ],
        [ 'A', [ .5, .5, 0, 0, 1 ], [ 2.5, 2] ],
        [ 'L', [ 0.5, 2 ] ],
        [ 'A', [ .5, .5, 0, 0, 1 ], [ 0, 1.5] ],
        [ 'L', [ 0, 0.5 ] ],
        [ 'A', [ .5, .5, 0, 0, 1 ], [ 0.5, 0 ] ],
        [ 'Z' ]
    ); 
    my @center = (1.5 + $offset_x, 1 + $offset_y);
    @path_params = map {
        if ($_->[0] ne 'Z') {
            $_->[- 1]->[0] += $offset_x;
            $_->[- 1]->[1] += $offset_y;
        }
        $_;
    } @path_params;

    my @param_strs = map { 
        my @str_array;
        my $elems = $_;
        for (1 .. @$elems - 1) {
           push @str_array, join(' ', @{$elems->[$_]});
        } 
        join ' ', $elems->[0], @str_array;
    } @path_params;
    {
        path => join(' ', @param_strs),
        center => \@center
    };
}

sub round_triangle_center {
    my $param_expect = create_round_rect_param; 
    my $lexer = Area::PathParser->lexer($param_expect->{path});

    my $parser = Area::PathParser->new;
        
    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    my $poly_and_elements = $path->polygons_and_svg_elements;
    ok(@$poly_and_elements == 1, 'expected parsed an element');

    my $poly = $poly_and_elements->[0]->{polygon};
    my $svg_elements = $poly_and_elements->[0]->{svg_elements};

    ok (@$svg_elements == 4, 'expected svg elements count is 4');
    my $element_are_arc = 1;
    
    for (@$svg_elements) {
        $element_are_arc = $_ isa Area::Arc;
        last if !$element_are_arc;
    }
    ok ($element_are_arc, 'expect all element is arc');

    my $poly_area = $poly->area;
    my $poly_center = $poly->center_by_points;

    my @arc_area_and_center;
    for (@$svg_elements) {
        push @arc_area_and_center, {
            area => $_->area,
            center => $_->center
        }
    }
    my $area = $poly_area;
    my @first_moment_areas;
    push @first_moment_areas, [
        $poly_area * $poly_center->[0],
        $poly_area * $poly_center->[1]
    ];
    for (@arc_area_and_center) {
        $area += $_->{area};
        push @first_moment_areas, [
            $_->{area} * $_->{center}->{x},
            $_->{area} * $_->{center}->{y}
        ];
    }
    my @first_moment_area = (0, 0);
    
    for (@first_moment_areas) {
        $first_moment_area[0] += $_->[0];
        $first_moment_area[1] += $_->[1];
    }
    my @center = map { $_ / $area } @first_moment_area;

    my @diff;
    for (0 .. $#center) {
       push @diff, abs($center[$_] - $param_expect->{center}->[$_]); 
    }
    ok ($diff[0] < 1e-5 && $diff[1] < 1e-5,
        'expect center calculation accuracy less than 1e-5');
    
}

round_triangle_center;
 
# vi: se ts=4 sw=4 et:
