package Area::Polygon;
use strict;

use Math::Trig qw(:pi acos);
use POSIX;
use Area::Polygon::Matrix;
use Area::Triangle;
use Area::Polygon::LineSegment;
use Area::Polygon::Vertex;
use Area::Polygon::IndexTrapezoidMap;
use Area::Polygon::Line;
use Area::Polygon::Error;

our $a, $b;

# construct polygon
sub new
{
    my $class = shift;
    my %args = @_;
    my $res;
    if ($args{p0} && $args{p1} && $args{p2}) {
        
        $res = bless {}, $class;
        $res->{vertices} = [];
        
        my $state = 0; 
        my @pt_keys;
        for (keys %args) {
            push @pt_keys, $_ if /p[[:digit:]]+/;
        }
        @pt_keys = sort { 
            my $num_a = substr $a, 1;
            my $num_b = substr $b, 1;
            $num_a <=> $num_b;
        } @pt_keys;
        for (@pt_keys) {
            $state = $res->add_point($args{$_});
            last if $state;
        }
        $res = undef if $state;
    }
    if ($res) {
        $res->{tolerance} = $args{tolerance} || 1E-5;
    }
    $res;
}

# add point
sub add_point
{
    my ($self, @points) = @_;
    return -1 if $self->{freeze}; 

    my $vertices = $self->{vertices};
    my $res = 0;
    for (@points) {
        my $pt = $_;
        if (scalar(@$pt) > 1) {
            my @pt = @$pt;
            my $vertex = Area::Polygon::Vertex->new(
                index => scalar @$vertices,
                point => \@pt);
            push @$vertices, $vertex;
        } else {
            $res = -1;
        }
        last if $res;
    }
    $res; 
}

# get vertex count
sub vertex_count
{
    my $self = shift;

    scalar @{$self->{vertices}};
}

# get point
sub point
{
    my ($self, $idx, %args) = @_;
    my $res = $self->vertex($idx)->point;

    if ($args{matrix}) {
        $res = $args{matrix}->apply(@$res);
    }

    $res;
}

# get all points
sub points {
    my ($self, %args) = @_;
    my @points;
    for (0 .. $self->vertex_count - 1) {
        push @points, $self->point($_, %args);
    }
    \@points;
}
# get vertex
sub vertex
{
    my ($self, $idx) = @_;
    $self->{vertices}->[$idx];
}

# get line segment
sub line {
    my ($self, $idx) = @_;
    $self->{lines}->[$idx];
}

# dupliate polygon
sub clone{
    my $self = shift;

    my %clone_src = (%$self);
    $clone_src{vertices} = [];
    delete $clone_src{lines};
    delete $clone_src{freeze};
    my $res = bless \%clone_src, __PACKAGE__;
    
    for (0 .. $self->vertex_count - 1) {
        $res->add_point($self->point($_)); 
    }
    if ($self->{freeze}) {
        $res->freeze;
    }
    $res; 
}

# create mirrored polygon against y axis
sub mirror {
    my $self = shift; 
    my $res = $self->clone;

    for (0 .. $res->vertex_count - 1) {
        $res->point($_)->[0] *= -1; 
    }
    $res; 
}

# calculate signed area
sub signed_area {
    my ($self) = @_;
    
    my $res = 0;
    for (0 .. $self->vertex_count - 1) {
        my @points = ($self->point($_ - 1), $self->point($_));
        $res += ($points[1]->[0] - $points[0]->[0])
            * ($points[0]->[1] + $points[1]->[1]) / 2;
    }
    $res;
}

# calculate area
sub area {
    abs($_[0]->signed_area);
}

# get center
sub center_by_points
{
    my $self = $_[0];
    my @fma = (0, 0);
    my $area = 0;
    for (0 .. $self->vertex_count - 1) {
        my @points = ($self->point($_ - 1), $self->point($_));
        if ($points[0]->[0] != $points[1]->[0]) {
            my $area0 = ($points[1]->[0] - $points[0]->[0])
                * ($points[0]->[1] + $points[1]->[1]) / 2;
            if ($area0 != 0) {
                my $center = $self->calculate_center_of_2_points_region(
                    @points);
                for (0 .. scalar(@$center) - 1) {
                    $fma[$_] += $center->[$_] * $area0;
                } 
            }
            $area += $area0;
        }
    }
    my @center = map { $_ / $area } @fma;
    \@center;
}

# calculate center of 2 points region
sub calculate_center_of_2_points_region
{
    my ($self, @points) = @_;

    my @x_points = ($points[0]->[0], $points[1]->[0]);
    my @y_points = ($points[0]->[1], $points[1]->[1]);
    my @center;
    if ($y_points[0] * $y_points[1] > 0) {
        my @rec_center; 
        my $rec_area;
        my $y_rec_height;
        my %triangle_param;
        if ($y_points[0] > 0) {
            if ($y_points[0] < $y_points[1]) {
                $y_rec_height = $y_points[0];
                %triangle_param = (
                    x1 => $x_points[0], y1 => $y_points[0],
                    x2 => $x_points[1], y2 => $y_points[0],
                    x3 => $x_points[1], y3 => $y_points[1]); 
            } elsif ($y_points[0] > $y_points[1]) {
                $y_rec_height = $y_points[1];
                %triangle_param = (
                    x1 => $x_points[0], y1 => $y_points[1],
                    x2 => $x_points[1], y2 => $y_points[1],
                    x3 => $x_points[0], y3 => $y_points[0]); 
            } else {
                $y_rec_height = $y_points[1];
            }
        } else {
            if ($y_points[0] > $y_points[1]) {
                $y_rec_height = $y_points[0];
                %triangle_param = (
                    x1 => $x_points[0], y1 => $y_points[0],
                    x2 => $x_points[1], y2 => $y_points[0],
                    x3 => $x_points[1], y3 => $y_points[1]); 
            } elsif ($y_points[0] < $y_points[1]) {
                $y_rec_height = $y_points[1];
                %triangle_param = (
                    x1 => $x_points[0], y1 => $y_points[1],
                    x2 => $x_points[1], y2 => $y_points[1],
                    x3 => $x_points[0], y3 => $y_points[0]); 
            } else {
                $y_rec_height = $y_points[1];
            }
        }  
        @rec_center = (($x_points[0] + $x_points[1]) / 2, $y_rec_height / 2);
        $rec_area = abs(($x_points[1] - $x_points[0]) * $y_rec_height);
        my @fma = map { $_ * $rec_area } @rec_center;
 
        my $area = $rec_area;
        if (%triangle_param) {
            my $triangle = Area::Triangle->new(%triangle_param);
            my $triangle_center = $triangle->center;
            my @triangle_center = (
                $triangle_center->{x}, $triangle_center->{y});
            my $triangle_area = $triangle->area;
            my @triangle_fma = map { $_ * $triangle_area } @triangle_center;
            for (0 .. $#triangle_fma) {
                $fma[$_] += $triangle_fma[$_]; 
            }
            $area += $triangle_area;
        }
        @center = map { $_ / $area } @fma;
    } else {
        my @lines = (
            Area::Polygon::Line->new(
                p1 => [ $x_points[0], $y_points[0] ],
                p2 => [ $x_points[1], $y_points[1] ]),
            Area::Polygon::Line->new(
                p1 => [ 0, 0 ],
                p2 => [ 1, 0 ])
        ); 
        my $intersec = Area::Polygon::Line->intersection(@lines);
        my $mx = $intersec->[0];
        my @triangles;
        push @triangles, Area::Triangle->new(
            x1 => $x_points[0],
            y1 => 0, 
            x2 => $mx,
            y2 => 0,
            x3 => $x_points[0],
            y3 => $y_points[0]) if $x_points[0] != $mx;   
        push @triangles, Area::Triangle->new(
            x1 => $mx,
            y1 => 0, 
            x2 => $x_points[1],
            y2 => 0,
            x3 => $x_points[1],
            y3 => $y_points[1]) if $x_points[1] != $mx;   

        my @fma = (0, 0);
        my $area = 0; 
        for (@triangles) {
            my $center = $_->center;
            my @center = ($center->{x}, $center->{y});
            my $triangle_area = $_->area;
            for (0 .. $#center) {
                $fma[$_] += $center[$_] * $triangle_area;
            }
            $area += $triangle_area;
        }
        @center = ($fma[0] / $area, $fma[1] / $area);
    }
    \@center;
}


# apply matrix
sub apply_matrix {
    my ($self, $matrix) = @_;
    for (0 .. $self->vertex_count - 1) {
        $self->vertex($_)->point($matrix->apply(@{$self->point($_)}));
    }
}

# create subpolygon
sub subpolygon {
    my ($self, $indices) = @_;

    my @params;
    my %index_map;
    for (@$indices) {
        my $pt_idx = scalar(@params) / 2;
        push @params, "p${pt_idx}", $self->point($_);
        $index_map{$pt_idx} = $_;
    } 
    my $poly = Area::Polygon->new(@params);
    {
        polygon => $poly,
        index_map => \%index_map
    }; 
}

# after you call freeze, you would not to add point. 
sub freeze {
    my $self = shift;
    $self->{freeze} = 1; 
    $self->{lines} = [];

    for (0 .. $self->vertex_count - 1) {
        my $line = Area::Polygon::LineSegment->new(
            v1 => $self->vertex($_),
            v2 => $self->vertex(($_ + 1) % $self->vertex_count));
        push @{$self->{lines}}, $line;
    }
}

# freeze the polygon if not
sub freeze_if_not {
    my $self = shift;
    $self->freeze if !$self->{freeze};
}

# compare point y coordinate first
sub _compare_point {
    my ($p1, $p2) = @_;
    $p1->[1] <=> $p2->[1] || $p1->[0] <=> $p2->[0]; 
}

# create subroutine to compare large y coordinate first.
sub create_large_y_coordinate_first_comparator {
    my $self = shift;
    sub {
        my ($a, $b) = @_;
        my $cmp_res;
        $cmp_res = $self->point($a)->[1] <=> $self->point($b)->[1];
        if (!$cmp_res) {
            $cmp_res = $self->point($a)->[0] <=> $self->point($b)->[0];
        }
        $cmp_res;
    }
}


# create sorted vertex indices
sub create_sorted_vert_indices {
    my $self = shift;
    my $src_indices = shift;
    if (!defined $src_indices) {
        $src_indices = [ 0 .. $self->vertex_count - 1 ];
    }
     
    my @indices = sort { 
        _compare_point $self->point($a), $self->point($b);
    } @$src_indices;

    \@indices;
}

# you get non zero if polygon points sequence is clockwize rotation.
sub is_clockwise {
    my $self = shift;

    my $indices = $self->create_sorted_vert_indices;
    $self->_is_clockwise($indices); 
}

# you get non zero if clockwize rotation when the coordinate system is
# followings.
#
#       +y 
#         ^
#         |     -> clockwise(cw)
#         |    <- counter clockwise(ccw)
#         |           0 
#         |           o 
#         |          /  \
#         |         o -- o
#         |   2(cw)      1(cw)
#         |   1(ccw)     2(ccw)
#         | 
# O(0, 0) +-------------->
#                   +x
sub _is_clockwise {
    my ($self, $sorted_indices) = @_; 
     
    my $highest_idx = $sorted_indices->[-1];

    my $lower_pt = $self->point($highest_idx);
    my $prev_pt = $self->point($highest_idx - 1);
    my $next_pt = $self->point($highest_idx + 1);

    my $res = $prev_pt->[0] < $next_pt->[0];
    $res;
}

# get tolerant scale
sub _tolerant_scale {
    my $self = shift;
    my $exp = POSIX::floor(POSIX::log10($self->{tolerance}));
    $exp = $exp < 0 ? $exp * - 1 : 0;
    10 ** $exp;
}

# find same points
sub find_same_points {
    my $self = shift;
    my $scale = $self->_tolerant_scale;
    
    my %coord_idx;
    my @duplicated;
    for (0 .. $self->vertex_count - 1) {
        my @pt = @{$self->point($_)};
        my @rounded = map { POSIX::round($scale * $_) / $scale; } @pt;
        
        my $indices;
        if (defined $coord_idx{$rounded[0], $rounded[1]}) {
            $indices = $coord_idx{$rounded[0], $rounded[1]};
            push @duplicated, join($;, $rounded[0], $rounded[1]);
        } else {
            $indices = [];
            $coord_idx{$rounded[0], $rounded[1]} = $indices;
        }
        push @$indices, $_; 
    } 
    my $res;
    if (scalar(@duplicated)) {
        $res = [];
        for (@duplicated) {
            push @$res, $coord_idx{$_};
        }
    }
    $res;
}

# last error
sub last_error {
    my ($self, $error) = @_;

    my $res = $self->{error};
    if (defined $error) {
        $self->{error} = $error;
    }
    $res;
}


# clear last error
sub clear_last_error {
    my $self = shift;
    delete $self->{error};
}

# dose need to rotate points
sub dose_need_to_rotate {
    my ($self) = @_;
}

# find intersection
sub find_intersections {
    my $self = shift;
    my $same_points = $self->find_same_points;
    my $res;
    if (!defined $same_points) {
        $res = $self->find_intersections_unsafe;
    }
    $res;
}

# find intersections
# assume the polygon dose not have same points
sub find_intersections_unsafe {
    my $self = shift;

    my $frozen = $self->{freeze};

    if (!$frozen) {
        $self->freeze;
    }
    my $rotation = $self->calculate_rotation(@_);
    my $res = $self->_find_intersections($rotation); 
    if (!$frozen) {
        delete $self->{freeze};
        delete $self->{lines};
    }
    $res;
}

# find intersection
sub _find_intersections {
    my ($self, $rotation) = @_;

    my $poly;
    if ($rotation != 0) {
        $poly = $self->clone;
        $poly->apply_matrix(
            Area::Polygon::Matrix->new(
                a => cos($rotation), c => -sin($rotation),
                b => sin($rotation), d => cos($rotation)));
    } else {
        $poly = $self;
    }
    my $frozen = $poly->{freeze};

    if (!$frozen) {
        $poly->freeze;
    }
    
    my $indices = $poly->create_sorted_vert_indices;  

    my $intersecs = $poly->_find_intersections_0($indices);

    if ($rotation != 0) {
        my $mat;
        $mat = Area::Polygon::Matrix->new(
            a => cos(-$rotation), c => -sin(-$rotation),
            b => sin(-$rotation), d => cos(-$rotation));
        for (keys %$intersecs) {
            my $pt = $intersecs->{$_};
            $intersecs->{$_} = $mat->apply($pt);
        }
    } 

    if (!$frozen) {
        delete $poly->{freeze}; 
        delete $poly->{lines};
    }
    $intersecs; 
}


# find intersection points
sub _find_intersections_0 {
    my ($self, $sorted_indices) = @_;

    my %intersections;  
    my %lines; 
    for (@$sorted_indices) {
        my $lines = $self->lines_from_vert_index($_);
        my $point = $self->point($_);
        my %cmp_res;
        $cmp_res{prev} = _compare_point($point, $lines->{prev}->p1);
        $cmp_res{next} = _compare_point($point, $lines->{next}->p2);
        if ($cmp_res{prev} > 0) {
            delete $lines{$lines->{prev}->v1->index}; 
        }
        if ($cmp_res{next} > 0) {
            delete $lines{$lines->{next}->v1->index}; 
        }
        if ($cmp_res{prev} < 0) {
            my $intersecs = $self->_find_line_intersections(\%lines,
                $lines->{prev}->v1->index); 
            $self->_update_intersections(\%intersections,
                $intersecs, $lines->{prev}->v1->index) if defined $intersecs;
            $lines{$lines->{prev}->v1->index} = $lines->{prev};
        }
        if ($cmp_res{next} < 0) {
            my $intersecs = $self->_find_line_intersections(\%lines,
                $lines->{next}->v1->index); 
            $self->_update_intersections(\%intersections,
                $intersecs, $lines->{next}->v1->index) if defined $intersecs;
            $lines{$lines->{next}->v1->index} = $lines->{next};
        }
    }
    \%intersections;
}


# find intersections
sub _find_line_intersections {
    my ($self, $lines, $line) = @_;

    my %intersecs;
    for (keys %$lines) {
        my $line_seg_0 = $self->line($line);
        my $line_seg_1 = $lines->{$_};
        
        my $intersec = Area::Polygon::Line->intersection(
            $line_seg_0, $line_seg_1);
        if ($intersec
            && $line_seg_0->in_range($intersec)
            && $line_seg_1->in_range($intersec)) {
            $intersecs{$_} = $intersec; 
        }
    }
    \%intersecs;
}

# update intersection
sub _update_intersections {
    my ($self, $intersec_map, $intersec_lines, $line_idx) = @_;
    for (keys %$intersec_lines) {
        my @key = sort {
            $a <=> $b;
        } ($_, $line_idx); 
        my $intersec = $intersec_lines->{$_};
        $intersec_map->{$key[0], $key[1]} = $intersec;
    }
}

# calculate rotation
sub calculate_rotation {
    my ($self, %args) = @_;
    my $frozen = $self->{freeze};

    if (!$frozen) {
        $self->freeze;
    }

    my $test_count = 10;
    if (defined $args{test_count}) {
        $test_count = $args{test_count};
    }
    my $rotation_division = 5;
    if (defined $args{rotation_division}) {
        $rotation_division = $args{rotation_division};
    }

    my $res = $self->_calculate_rotation(
        $self->_rounded_directions_y_positive,
        $test_count, $rotation_division); 
    
    if (!$frozen) {
        delete $self->{freeze};
        delete $self->{lines};
    }
    $res;
}

# find nearly value 
sub _find_nearly_value {
    my ($num_array, $value, $tolerance) = @_;
    my $l = 0;
    my $r = scalar(@$num_array) - 1;
    my $last_l;
    my $last_r;
    my $res;
    while ($l <= $r) {
        my $idx = POSIX::floor(($l + $r) / 2);
        my $diff = $num_array->[$idx] - $value;
        if ($diff < 0 && -$diff > $tolerance) {
            $last_l = $l;
            $l = $idx + 1;
        } elsif ($diff > 0 && $diff > $tolerance) {
            $last_r = $r;
            $r = $idx - 1;     
        } else {
            $res = $num_array->[$idx];
            last;
        }
    } 
    $res;
}

# calculate rotation
sub _calculate_rotation {
    my ($self, $rounded_directions_y_positive,
        $test_count, $rotation_division) = @_;

    my $res;
    if (!defined $rounded_directions_y_positive->{1, 0}) {
        my $sp_index = $self->_find_same_y_coordinate_index_with_angle;
        if (!defined $sp_index) {
            $res = 0; 
        }
    }
    if (!defined $res and $test_count > 1) {
        my $radians = $self->_calculate_radians(
            $rounded_directions_y_positive); 
        unshift @$radians, 0 if $radians->[0] != 0;
        my $indices = $self->_calculate_angle_difference_indices(
            $radians); 

       
        my $try_count = 1;
        FIND_RADIAN: for (reverse @$indices) {
            my $rad_idx = $_;
            for (2 .. $rotation_division) {
                my $rad_1 = $radians->[$rad_idx + 1] + $radians->[$rad_idx];
                my $div = $_;
                for (1 .. $div - 1) {
                    my $rad = ($rad_1 * $_) / $div;
                    my $nearly_rad = _find_nearly_value(
                        $radians, $rad, $self->{tolerance});
                    next if defined $nearly_rad;
                    $rad *= -1;
                    my $sp_idx;
                    $sp_idx = $self->_find_same_y_coordinate_index_with_angle(
                        $rad); 
                    $try_count++;
                    if (!defined $sp_idx) {
                        $res = $rad;
                        last FIND_RADIAN;
                    }
                    last FIND_RADIAN if $try_count > $test_count; 
                }
            }
        }
    }
    $res;
}


# find y coordinate index with a with angle 
sub _find_same_y_coordinate_index_with_angle {
    my ($self, $angle) = @_;

    my $mat;
    if ($angle) {
        $mat = Area::Polygon::Matrix->new(
            a => cos($angle), c => -sin($angle),
            b => sin($angle), d => cos($angle));
    }
    my @points = sort {
        _compare_point $a, $b
    } @{$self->points(matrix => $mat)};
    $self->_find_same_y_coordinate_index(\@points);
}


# find same y coordinate index
sub _find_same_y_coordinate_index {
    my ($self, $sorted_points) = @_;

    my $res;
    my $y_coord = $sorted_points->[0]->[1]; 
    for (1 .. scalar(@$sorted_points) - 1) {
        my $next_y_coord = $sorted_points->[$_]->[1];
        if (($y_coord <=> $next_y_coord) == 0) {
            $res = [ $_ - 1, $_ ];
            last;      
        }
        $y_coord = $next_y_coord;
    }
    $res; 
}


# calculate angle difference indices
sub _calculate_angle_difference_indices {
    my ($self, $radians) = @_;
    my @indices = 0 .. scalar(@$radians) - 2; 
    my @res = sort { 
        my $diff_a = $radians->[$a + 1] - $radians->[$a]; 
        my $diff_b = $radians->[$b + 1] - $radians->[$b];
        $diff_a <=> $diff_b;
    } @indices;
    \@res;
}


# calculate radians
sub _calculate_radians {
    my ($self, $dir_map) = @_;
    my @radians;
    for (keys %$dir_map) {
        my @dir = @{$dir_map->{$_}->[0]};
        push @radians, acos($dir[0]);        
    }
    @radians = sort { $a <=> $b } @radians;
    \@radians;
}

# you get true if this polygon have to be rotated for motone polygon
sub dose_need_to_rotate {
    my $self = shift;
    my $freezed = $self->{freeze};

    if (!$freezed) {
        $self->freeze;
    }
    my $res = $self->_dose_need_to_rotate(
        $self->_rounded_directions_y_positive); 
    
    if (!$freezed) {
        delete $self->{lines};
    }
    $res;
}


# dose need to rotate points
sub _dose_need_to_rotate {
    my ($self, $dir_map) = @_;
    defined $dir_map->{1,0};
}

# create rounded line direction having positive y coordinate
sub rounded_directions_y_positive {
    my $self = shift;
    my $frozen = $self->{freeze};
    if (!$frozen) {
        $self->freeze;
    } 
    my $res = $self->_rounded_directions_y_positive;
    if (!$frozen) {
        delete $self->{freeze};
        delete $self->{lines};
    }
    $res;
}

# create rounded line direction having positive y coordinate
sub _rounded_directions_y_positive {
    my $self = shift;
    my $dir_map = $self->_rounded_directions;

    my %res;
    for (keys %$dir_map) {
        my @r_dir_array;
        for (@{$dir_map->{$_}}) { 
            my @dir = @$_;
            if ($dir[1] < 0) {
                @dir = map { $_ * -1 } @dir;
            } elsif ($dir[1] == 0 && $dir[0] < 0) {
                $dir[0] *= -1;
            }
            push @r_dir_array, \@dir;
        }
        for (@r_dir_array) {
            my $lines;
            if (defined $res{$_->[0], $_->[1]}) {
                $lines = $res{$_->[0], $_->[1]};
            } else {
                $lines = [];
                $res{$_->[0], $_->[1]} = $lines;
            }
            push @$lines, $_;
        }
    }
    \%res;
}

# create rounded line directions with tolerance
sub rounded_directions {
    my $self = shift;
    my $frozen = $self->{freeze};
    if (!$frozen) {
        $self->freeze;
    } 
    my $res = $self->_rounded_directions;
    if (!$frozen) {
        delete $self->{freeze};
        delete $self->{lines};
    }
    $res;
}

# create rounded line directions with tolerance
sub _rounded_directions {
    my $self = shift;
    my %res;
    my $dir_map = $self->_line_directions;
    my $scale = $self->_tolerant_scale;
    for (keys %$dir_map) {
        my $dir_array = $dir_map->{$_};
        my @r_dir_array;
        for (@$dir_array) {
            my @r_dir = map { POSIX::round($scale * $_) / $scale; } @$_;
            push @r_dir_array, \@r_dir;
        }

        for (@r_dir_array) {
            my $r_dir = $_;
            for (0 .. 1) {
                if (abs(1 - abs($r_dir->[$_])) < $self->{tolerance}) {
                    $r_dir->[$_] = $r_dir->[$_] <=> 0;
                } 
            }
        }
           
        for (@r_dir_array) {
            my @r_dir = @$_;
            my $lines;
            if (defined $res{$r_dir[0], $r_dir[1]}) {
                $lines = $res{$r_dir[0], $r_dir[1]};
            } else {
                $lines = [];
                $res{$r_dir[0], $r_dir[1]} = $lines;
            }
            push @$lines, \@r_dir;  
        }
    }
    \%res;
}

# calculate line directions
sub line_directions {
    my $self = shift;
    my $frozen = $self->{freeze};
    if (!$frozen) {
        $self->freeze;
    } 
    my $res = $self->_line_directions;
    if (!$frozen) {
        delete $self->{freeze};
        delete $self->{lines};
    }
    $res;
}

# create line directions
sub _line_directions {
    my $self = shift;

    my %res;
    for (0 .. $self->vertex_count - 1) {
        my $line = $self->line($_);
        my @dir = @{$line->direction};
        my $lines;
        if (defined $res{$dir[0], $dir[1]}) {
            $lines = $res{$dir[0], $dir[1]};
        } else {
            $lines = [];
            $res{$dir[0], $dir[1]} = $lines;
        }
        push @$lines, \@dir;  
    } 
    \%res;
}

# check prerequisite to split motone polygons
sub is_ready_to_monotonize {
    my ($self, %args) = @_;
    my $res = 0;
    my $same_points = $self->find_same_points;
    if (!defined $same_points) {
        my $intersecs = $self->find_intersections_unsafe;
        if ($intersecs && keys %$intersecs) {
            $self->last_error(
                Area::Polygon::Error->new(
                    error_str => 'Polygon has intersection.',
                    data => $intersecs));
            
        } else {
            $res = 1;
        }
    } else {
        $self->last_error(
            Area::Polygon::Error->new(
                error_str => 'Polygon has same points.',
                data => $same_points));
    }
    $res;
}


# calculate parameter to split motone polygons
sub calculate_monotone_params {
    my ($self, @args) = @_;
    my $res;
    if ($self->is_ready_to_monotonize) {
        my $rotation = $self->calculate_rotation(@args);
        my $poly = $self->clone;
        if ($rotation != 0) {
            $poly->apply_matrix(
                Area::Polygon::Matrix->new(
                    a => cos($rotation), c => -sin($rotation),
                    b => sin($rotation), d => cos($rotation)));
        }
        my $indices = $poly->create_sorted_vert_indices;

        if (!$poly->_is_clockwise($indices)) {
            $poly = $poly->mirror;
            $indices = $poly->create_sorted_vert_indices;
        }
        $poly->freeze;
        my %res = ( 
            indices => $indices,
            polygon => $poly
        ); 
        $res = \%res;
    }
    $res;
}


# calculate monotone indices
sub monotone_indices {
    my ($self, @args) = @_;
    my $params = $self->calculate_monotone_params(@args);
    my $res;
    if (defined $params) {
        $res = $params->{polygon}->_monotone_indices($params->{indices});
    }
    $res;
}

# calculate monotone mountain indices
sub monotone_mountain_indices {
    my ($self, @args) = @_;
    my $params = $self->calculate_monotone_params(@args);
    my $res;
    if (defined $params) {
        $res = $params->{polygon}->_monotone_mountain_indices(
            $params->{indices});
    }
    $res;
}

# calculate monotone indices
sub monotone_indices_unsafe {
    my $self = $_[0];
    my $indices = $self->create_sorted_vert_indices;
    $self->_monotone_indices($indices);
}

# calculate monotone indices
sub _monotone_indices {
    my $self = shift;
    my $indices = shift;
    my $index_trapezoid_map = Area::Polygon::IndexTrapezoidMap->new(
        count_of_lines => scalar @{$self->{lines}});   
    my @cusps;
    $self->create_trapezoid_map(
        indices => $indices,
        trapezoid_map => $index_trapezoid_map,
        cusps => \@cusps);
    my $diagonals = $self->create_diagonals_from_cusps(\@cusps,
        $index_trapezoid_map);
    $self->split_polygon_by_diagonals($diagonals);
}


# calculate monotone mountain indices
sub monotone_mountain_indices_unsafe {
    my $self = shift;
    my $indices = $self->create_sorted_vert_indices;
    $self->_monotone_mountain_indices($indices); 
}

# calculate monotone mountain indices
sub _monotone_mountain_indices {
    my $self = shift;
    my $indices = shift;
    my $index_trapezoid_map = Area::Polygon::IndexTrapezoidMap->new(
        count_of_lines => scalar @{$self->{lines}});   
    my @cusps;
    my %vert_lines_map;
    $self->create_trapezoid_map(
        indices => $indices,
        trapezoid_map => $index_trapezoid_map,
        cusps => \@cusps,
        vert_lines_map => \%vert_lines_map);
    my $diagonals_from_cusps = $self->create_diagonals_from_cusps(\@cusps,
        $index_trapezoid_map);
    my $diagonals_from_vert_lines_map =
        $self->create_diagonals_from_vert_lines_map(
            \%vert_lines_map,$index_trapezoid_map); 
    
    my %diagonals = (%$diagonals_from_cusps, %$diagonals_from_vert_lines_map); 

    $self->split_polygon_by_diagonals(\%diagonals);
}


# create trapezoid map
sub create_trapezoid_map {
    my ($self, %args) = @_;
    my $indices = $args{indices};
    my $index_trapezoid_map = $args{trapezoid_map};
    my $cusps = $args{cusps}; 
    my $vert_lines_map = $args{vert_lines_map};
    if (!defined $cusps) {
        $cusps = [];
    }
    if (!defined $vert_lines_map) {
        $vert_lines_map = { };
    }
    my %lines;
    for (@$indices) {
        my $lines = $self->lines_from_vert_index($_);
        my $point = $self->point($_);
        my %cmp_res;
        $cmp_res{prev} = _compare_point($point, $lines->{prev}->p1);
        $cmp_res{next} = _compare_point($point, $lines->{next}->p2);
        if ($cmp_res{prev} > 0) {
            delete $lines{$lines->{prev}->v1->index}; 
        }
        if ($cmp_res{next} > 0) {
            delete $lines{$lines->{next}->v1->index}; 
        }
        $self->create_trapezoid_line($_, \%lines, \%cmp_res,
            $index_trapezoid_map, $cusps, $vert_lines_map);
        if ($cmp_res{prev} < 0) {
            $lines{$lines->{prev}->v1->index} = $lines->{prev};
        }
        if ($cmp_res{next} < 0) {
            $lines{$lines->{next}->v1->index} = $lines->{next};
        }
    }
    
}

# get lines from vert index
sub lines_from_vert_index {
    my ($self, $idx) = @_;
    {
        prev => $self->line($idx - 1),
        next => $self->line($idx)
    };
}

# create trapezoid line
sub create_trapezoid_line {
    my ($self, $idx, $lines, $vert_status, 
        $index_trapezoid_map,
        $cusps, $vert_lines_map) = @_;

    my $line_intersecs = $self->calculate_intersections($lines, $idx);

    my @line_intersecs;
    my %intersections;
    if ($vert_status->{prev} * $vert_status->{next} > 0) {
        my $vec_angle = $self->calculate_vector_angle($idx); 
        if ($vec_angle > pi) { 

            if (scalar @{$line_intersecs->{plus}}) {
                push @line_intersecs, $line_intersecs->{plus}->[0];
                $intersections{plus} = $line_intersecs->{plus}->[0];
            }
            if (scalar @{$line_intersecs->{minus}}) {
                push @line_intersecs, $line_intersecs->{minus}->[-1];
                $intersections{minus} = $line_intersecs->{minus}->[-1];
            }
            push @$cusps, {
                index => $idx,
                status => $vert_status,
                intersections => \%intersections
            };

        }
    } elsif ($vert_status->{prev} > 0) {
        $intersections{plus} = $line_intersecs->{plus}->[0];
        push @line_intersecs, $line_intersecs->{plus}->[0];
    } else {
        $intersections{minus} = $line_intersecs->{minus}->[-1];
        push @line_intersecs, $line_intersecs->{minus}->[-1];
    }
    $vert_lines_map->{$idx} = \%intersections;
    for (@line_intersecs) {
        $index_trapezoid_map->add_trapezoid(
            index => $_->{line}->v1->index,
            trapz_line => $_);
    }
}


# calculate vector angle
sub calculate_vector_angle {
    my ($self, $vert_idx) = @_;
    $self->_calculate_vector_angle(
        $vert_idx - 1,
        $vert_idx,
        ($vert_idx + 1) % $self->vertex_count);
}

# calculate vector angle
sub _calculate_vector_angle {
    my ($self, $idx0, $idx1, $idx2) = @_;
    my @lines = (
        Area::Polygon::Line->new(
            p1 => $self->point($idx0),
            p2 => $self->point($idx1)),
        Area::Polygon::Line->new(
            p1 => $self->point($idx1),
            p2 => $self->point($idx2)));

    my @dirs = map { $_->direction } @lines;
    
    my @each_angles = map {
        my $res;
        if ($_->[0] != -1) {
            $res = acos($_->[0]);
            $res *= -1 if ($_->[1] < 0);
        } else {
            $res = pi;
        }
        $res;
    } @dirs;
    my $res = pi - ($each_angles[0] - $each_angles[1]);
    my $tmp_val = $res / pi2;
    $tmp_val = POSIX::floor($tmp_val);
    $res -= $tmp_val * pi2;
    $res;
}



# calculate intersections
sub calculate_intersections {
    my ($self, $lines, $idx, $id_trapz_map) = @_;
    my $pt = $self->point($idx);
    my $line = Area::Polygon::Line->new(
        p1 => $pt,
        p2 => [
            $pt->[0] + 1,
            $pt->[1]
        ]);
    my %line_intersecs = ( 
        minus => [],
        plus => []
    );
    for (keys %$lines) {
        my $line_seg = $lines->{$_};
        my $intersec = Area::Polygon::Line->intersection($line_seg, $line);
        if ($intersec) {
            my $key = $intersec->[0] < $pt->[0] ? 'minus' : 'plus';
            push @{$line_intersecs{$key}}, {
                line => $line_seg,
                coordinate_index => $pt->[1],
                intersection => $intersec,
                support_index => $idx
            };
        }
    } 
    for (keys %line_intersecs) {
        my @line_intersecs_s = sort { 
            $a->{intersection}->[0] <=> $b->{intersection}->[0];
        } @{$line_intersecs{$_}};
        $line_intersecs{$_} = \@line_intersecs_s;
    }
    \%line_intersecs;
}


# create diagonals from cusp
sub create_diagonals_from_cusps {
    my ($self, $cusps, $index_trapezoid_map) = @_;
    my %diagonals;
    for (@$cusps) {
        my $cusp = $_;
        my $status = $cusp->{status};
        my $lines = $self->lines_from_vert_index($_->{index});
        if ($status->{prev} > 0) { # and $status->{next} > 0
            # lower cusp
            my %intsec_trapzidx_map;
            for (keys %{$cusp->{intersections}}) {
                my $intsec_key = $_;
                my $origin_idx =
                    $cusp->{intersections}->{$intsec_key}->{line}->v1->index;

                my $line_idx = $origin_idx;
                my $trapz_intersec_idx =
                    $index_trapezoid_map->find_trapezoid_index(
                        index => $line_idx,
                        coordinate_index => $self->point($cusp->{index})->[1]);
                $intsec_trapzidx_map{$intsec_key} = {
                    index => $line_idx,
                    itersec_key => $intsec_key,
                    trapezoid_index => $trapz_intersec_idx
                };
                my $trapz_count = $index_trapezoid_map->trapezoid_line_count(
                    index => $line_idx);
                if ($trapz_intersec_idx == $trapz_count - 1) {
                    my $line = $cusp->{intersections}->{$intsec_key}->{line};
                    my $cmp = $self->create_large_y_coordinate_first_comparator;
                    my @vert_indices = sort {
                        $cmp->($a, $b);
                    } ($line->v1->index, $line->v2->index);
                    my @diag_indices = sort {
                        $a <=> $b;
                    } ($vert_indices[-1], $cusp->{index});
                    $diagonals{$diag_indices[0], $diag_indices[1]} =
                        \@diag_indices;
                } 
            }
            my $diagonal_idx = $self->find_diagonal_index_from_lower_cusp(
                $index_trapezoid_map, $cusp, \%intsec_trapzidx_map);
            if (defined $diagonal_idx) {
                my @diag_indices = sort {
                    $a <=> $b;
                } ($diagonal_idx, $cusp->{index});
                $diagonals{$diag_indices[0], $diag_indices[1]} =
                    \@diag_indices;
            }

        } else {
            # $status->{prev} < 0 && $status->{next} < 0
            # upper cusp
            my %intsec_trapzidx_map;
            for (keys %{$cusp->{intersections}}) {
                my $intsec_key = $_;
                my $origin_idx =
                    $cusp->{intersections}->{$intsec_key}->{line}->v1->index;
                my $line_idx = $origin_idx;
                my $trapz_intersec_idx =
                    $index_trapezoid_map->find_trapezoid_index(
                        index => $line_idx,
                        coordinate_index => $self->point($cusp->{index})->[1]);

                $intsec_trapzidx_map{$intsec_key} = {
                    index => $line_idx,
                    itersec_key => $intsec_key,
                    trapezoid_index => $trapz_intersec_idx
                };
                if ($trapz_intersec_idx == 0) {
                    my $line = $cusp->{intersections}->{$intsec_key}->{line};
                    my $cmp = $self->create_large_y_coordinate_first_comparator;
                    my @vert_indices = sort {
                        $cmp->($a, $b);
                    } ($line->v1->index, $line->v2->index);
                    my @diag_indices = sort {
                        $a <=> $b;
                    } ($vert_indices[0], $cusp->{index});
                    $diagonals{$diag_indices[0], $diag_indices[1]} =
                        \@diag_indices;
                } 
            }
            
            my $diagonal_idx = $self->find_diagonal_index_from_upper_cusp(
                $index_trapezoid_map, $cusp, \%intsec_trapzidx_map);
            if (defined $diagonal_idx) {
                my @diag_indices = sort {
                    $a <=> $b;
                } ($diagonal_idx, $cusp->{index});
                $diagonals{$diag_indices[0], $diag_indices[1]} =
                    \@diag_indices;
            }
        }
    }
    \%diagonals; 
}


# create diagonals from vert lines map
sub create_diagonals_from_vert_lines_map {
    my ($self, $vert_lines_map, $index_trapezoid_map) = @_;
    my %diagonals;
    for (keys %$vert_lines_map) {
        my $idx = $_;
        my $intersections = $vert_lines_map->{$idx}; 
        my $vert_lines = $self->lines_from_vert_index($idx);
        my $intersec;
        if (!defined $intersections->{minus}) {
            # vertex is in left side chain
            $intersec = $intersections->{plus};
        } elsif (!defined $intersections->{plus}) {
            # vertex is in right side chain
            $intersec = $intersections->{minus};
        } else {
            # vertex is cusp
            # you do nothing.
        }
        if (defined $intersec) {
            my $line_idx = $intersec->{line}->v1->index;
            my $trapz_idx = $index_trapezoid_map->find_trapezoid_index( 
                index => $line_idx,
                coordinate_index => $self->point($idx)->[1]);

            my $intersec_count = $index_trapezoid_map->trapezoid_line_count(
                index => $line_idx);
            if ($trapz_idx == $intersec_count - 1) {
                my $counter_chain_seg = $self->line($line_idx);
                my $cmp = $self->create_large_y_coordinate_first_comparator;
                my @couter_chain_verts = sort {
                    $cmp->($a, $b);    
                } ($counter_chain_seg->v1->index,
                    $counter_chain_seg->v2->index);
                my $counter_vert_idx = $couter_chain_verts[-1];
                if ($vert_lines->{prev}->v1->index != $counter_vert_idx
                    && $vert_lines->{next}->v2->index != $counter_vert_idx) {
                    my @diagonal = sort {
                        $a <=> $b
                    } ($idx, $counter_vert_idx);
                    $diagonals{$diagonal[0],$diagonal[1]} = \@diagonal;
                }
            }
        }
    }
    \%diagonals;
}

# find diagonal from upper cusp
sub find_diagonal_index_from_upper_cusp {
    my ($self, $index_trapezoid_map,
        $cusp, $intersec_trapzidx_map) = @_;
    my $vertex_compare = $self->create_large_y_coordinate_first_comparator;
    my $neighbor_lines = $self->lines_from_vert_index($cusp->{index}); 
    my @neighbor_verts = (
        $neighbor_lines->{prev}->v1->index,
        $neighbor_lines->{next}->v2->index 
    );
    my @support_indices;
    for (keys %$intersec_trapzidx_map) {
        my $trapz_param = $intersec_trapzidx_map->{$_};
        my $trapz_count = $index_trapezoid_map->trapezoid_line_count(
            index => $trapz_param->{index});
        if ($trapz_param->{trapezoid_index} == $trapz_count - 1) {
            my $trapz_line = $index_trapezoid_map->trapezoid_line(
                line_index => $trapz_param->{index}, 
                index => $trapz_param->{trapezoid_index});
            
            my @line_verts = (
                $trapz_line->{line}->v1->index, 
                $trapz_line->{line}->v2->index
            );
            my $trapezoid = 1;
            for (@line_verts) {
                my $vert_idx = $_;
                for (@neighbor_verts) {
                    $trapezoid = abs($_ <=> $vert_idx);
                    last if !$trapezoid;
                }
                last if !$trapezoid;
            } 
            if ($trapezoid) {
                for (@line_verts) {
                    my $cmp_res;
                    $cmp_res = $vertex_compare->($cusp->{index}, $_);

                    if ($cmp_res < 0) {
                        push @support_indices, $_; 
                        last;
                    }
                }
            }
        }
    }
    
    @support_indices = sort {
        $vertex_compare->($a, $b); 
    } @support_indices;
    @support_indices[-1];
}

# find diagonal index from lower cusp
sub find_diagonal_index_from_lower_cusp {
    my ($self, $index_trapezoid_map,
        $cusp, $intersec_trapzidx_map) = @_;
    my $vertex_compare = $self->create_large_y_coordinate_first_comparator;
    my $neighbor_lines = $self->lines_from_vert_index($cusp->{index}); 
    my @neighbor_verts = (
        $neighbor_lines->{prev}->v1->index,
        $neighbor_lines->{next}->v2->index 
    );
    my @support_indices;
    for (keys %$intersec_trapzidx_map) {
        my $trapz_param = $intersec_trapzidx_map->{$_};
        if ($trapz_param->{trapezoid_index} == 0) {
            my $trapz_line = $index_trapezoid_map->trapezoid_line(
                line_index => $trapz_param->{index}, 
                index => $trapz_param->{trapezoid_index});
            my @line_verts = (
                $trapz_line->{line}->v1->index, 
                $trapz_line->{line}->v2->index
            );
            my $trapezoid = 1;
            for (@line_verts) {
                my $vert_idx = $_;
                for (@neighbor_verts) {
                    $trapezoid = abs($_ <=> $vert_idx);
                    last if !$trapezoid;
                }
                last if !$trapezoid;
            }
            if ($trapezoid) {
                for (@line_verts) {
                    my $cmp_res;
                    $cmp_res = $vertex_compare->($cusp->{index}, $_);
                    if ($cmp_res < 0) {
                        push @support_indices, $_; 
                        last;
                    }
                }
            }
        }
    }
    
    @support_indices = sort {
        $vertex_compare->($a, $b); 
    } @support_indices;
    @support_indices[0]; 
}

# compare number array
sub compare_number_array {
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

# split polygon by diagonals
sub split_polygon_by_diagonals {
    my ($self, $diagonals) = @_;
    my @diagonal_keys = sort {
        my @indices_a = split $;, $a;
        my @indices_b = split $;, $b;
        my $res = $indices_a[0] <=> $indices_b[0];
        if ($res == 0) {
            $res = $indices_a[1] <=> $indices_b[1];
        } 
        $res;
    } keys %$diagonals; 
    sub find_polygon_point_index {
        my ($polygon, $vert_idx) = @_;
        my $l = 0;
        my $r = scalar(@$polygon) - 1;
        my $res = -1; 
        while ($l <= $r) {
            my $idx = POSIX::floor(($l + $r) / 2);
            if ($polygon->[$idx] < $vert_idx) {
                $l = $idx + 1;
            } elsif ($polygon->[$idx] > $vert_idx) {
                $r = $idx - 1;
            } else {
                $res = $idx;
                last;
            }
        }
        $res;
    }
 
    sub find_polygon_pos {
        my ($vert_index_pair, $polygon_indices) = @_;
        my $l = 0;
        my $r = scalar(@$polygon_indices) - 1;
        my $res = -1;
        for (0 .. scalar(@$polygon_indices) - 1) {
            my @pt_idx = (
                find_polygon_point_index(
                    $polygon_indices->[$_], $vert_index_pair->[0]),
                find_polygon_point_index(
                    $polygon_indices->[$_], $vert_index_pair->[1])
            );
            if ($pt_idx[0] >= 0 && $pt_idx[1] >= 0) {
                $res = $_;
                last;
            }
        }
        $res;
    }
    my @polygon_indices = ([0 .. $self->vertex_count - 1]);
    for (@diagonal_keys) {
        my $diagonal = $diagonals->{$_};
        my $polypos = find_polygon_pos($diagonal, \@polygon_indices); 
        if ($polypos >= 0) {
            my $poly = $polygon_indices[$polypos]; 
            if ($diagonal->[1] <= $poly->[-1]) {
                my @indices = (
                    find_polygon_point_index($poly, $diagonal->[0]),
                    find_polygon_point_index($poly, $diagonal->[1])
                );
                if ($indices[0] >= 0 && $indices[1] - $indices[0] > 1) {
                    my @poly_end = splice @$poly, $indices[1]; 
                    push @$poly, $poly_end[0];
                    my @rest_poly = splice @$poly, $indices[0]; 
                    push @$poly, @rest_poly[0];
                    push @$poly, @poly_end; 
                    splice @polygon_indices, $polypos, 1, $poly, \@rest_poly;
                }
            }
        } 
    }
    @polygon_indices = sort {
        compare_number_array $a, $b;
    } @polygon_indices;
    \@polygon_indices;
}

# divide polygon into triangles
sub triangulation_monotone {
    my ($self) = @_; 
    my $indices = $self->monotone_triangulation_indices;
    my $res;
    if (defined $indices) {
        $res = $self->_triangles($indices);
    }
    $res; 
}

# divide polygon into triangles
sub triangulation_monotone_mountain {
    my ($self) = @_; 
    my $indices = $self->monotone_mountain_triangulation_indices;
    my $res;
    if (defined $indices) {
        $res = $self->_triangles($indices);
    }
    $res; 
}


# separate triangles
sub _triangles {
    my ($self, $indices) = @_;
    my @triangles;
    for (@$indices) {
        my $triangle_indices  = $_;
        my %param;
        for (0 .. @$triangle_indices - 1) {
            my $pt = $self->point($triangle_indices->[$_]);
            my $param_idx = $_ + 1;
            $param{"x$param_idx"} = $pt->[0];
            $param{"y$param_idx"} = $pt->[1];
        }
        push @triangles, Area::Triangle->new(%param); 
    }
    \@triangles;
}

# monotone triangulation
sub monotone_triangulation_indices
{
    my ($self, @args) = @_;
    my $params = $self->calculate_monotone_params(@args);
    my $res;
    if (defined $params) {
        my $monotone_indices = $params->{polygon}->_monotone_indices(
            $params->{indices});

        $res = $params->{polygon}->_monotone_triangulation_indices(
            $monotone_indices);
    }
    $res;
}

# monotone mountain triangulation
sub monotone_mountain_triangulation_indices
{
    my ($self, @args) = @_;
    my $params = $self->calculate_monotone_params(@args);
    my $res;
    if (defined $params) {
        my $monotone_indices = $params->{polygon}->_monotone_mountain_indices(
            $params->{indices});

        $res = $params->{polygon}->_monotone_triangulation_indices(
            $monotone_indices);
    }
    $res;
}


# monotone triangulation
sub _monotone_triangulation_indices
{
    my ($self, $monotone_indices) = @_;

    my @triangle_indices;
    for (@$monotone_indices) {
        if (@$_ > 3) {
            my $sub_poly = $self->subpolygon($_);
            $sub_poly->{polygon}->freeze;
            my $triangle_indices = 
                $sub_poly->{polygon}->_monotone_triangle_indices_unsafe;
            for (@$triangle_indices) {
                my @triangle_indices_0 = map { 
                    $sub_poly->{index_map}->{$_}; 
                } @$_;
                push @triangle_indices, \@triangle_indices_0;
            } 
        } else {
            push @triangle_indices, $_;
        }
    } 
    \@triangle_indices;
}



# create triangle indices
# the polygon must be monotone.
# the polygon must be clockwise.
sub _monotone_triangle_indices_unsafe {
    my $self = shift;
    my $indices = $self->create_sorted_vert_indices;

    my $start_idx = $indices->[0];
    my $end_idx = $indices->[-1];

    my %left_chain;
    my %right_chain;

    my $idx;
    $idx = ($start_idx + 1) % $self->vertex_count;
    while ($idx != $end_idx) {
        $left_chain{$idx} = $idx;
        $idx = ($idx + 1) % $self->vertex_count;
    }
    $idx = ($start_idx - 1) % $self->vertex_count;
    while ($idx != $end_idx) {
        $right_chain{$idx} = $idx;
        $idx = ($idx - 1) % $self->vertex_count;
    }
    $self->_monotone_triangle_indices_unsafe_0(
        $indices, \%left_chain, \%right_chain);
}

# create triangle indices
# the polygon must be monotone.
# the polygon must be clockwise.
sub _monotone_triangle_indices_unsafe_0 {
    my ($self, $indices, $left_chain, $right_chain) = @_;
    my %state;
    my @triangle_indices;
    my @reflex_vertices = ($indices->[0]);
    for (1 .. @$indices - 2) {
        my $vert_chain;
        my $idx = $indices->[$_];
        if (defined $left_chain->{$idx}) {
            $vert_chain = 'left';
        } elsif (defined $right_chain->{$idx}) {
            $vert_chain = 'right';
        }
        if (@reflex_vertices > 1) {
            if ($state{chain} eq $vert_chain) {
                while (@reflex_vertices > 1) {
                    my @vert_indices;
                    if ($state{chain} eq 'left') {
                        @vert_indices = (
                            $reflex_vertices[-2],
                            $reflex_vertices[-1],
                            $idx);
                    } else {
                        @vert_indices = (
                            $idx,
                            $reflex_vertices[-1],
                            $reflex_vertices[-2]);
                    }
                    my $vec_angle = $self->_calculate_vector_angle(
                        @vert_indices);

                    if ($vec_angle >= pi) { 
                        last;
                    } else {
                        push @triangle_indices, \@vert_indices;
                        pop @reflex_vertices; 
                    }
                }
            } else {
                while (@reflex_vertices > 1) {
                    push @triangle_indices, 
                        [$idx, $reflex_vertices[0], $reflex_vertices[1]];
                    shift @reflex_vertices; 
                }
                $state{chain} = $vert_chain;
            }
        } else {
            $state{chain} = $vert_chain;
        }
        push @reflex_vertices, $idx;
    }

    my $idx = $indices->[-1]; 
    for (0 .. @reflex_vertices - 2) {
        push @triangle_indices, 
            [$idx, $reflex_vertices[$_], $reflex_vertices[$_ + 1]];
    }
    \@triangle_indices; 
}
1;
__END__


=pod

=head1 Area::Polygon

represent closed polygon.

=head2 new

construct a polygon object
You have to start create triangle

 my $poly = Area::Polygon->new(p0 => [0, 0], p1 => [1, 0], p2=> [0, 1]);


=head2 add_point

add a point

 $poly->add_point([1, 1]);


# vi: se ts=4 sw=4 et:
