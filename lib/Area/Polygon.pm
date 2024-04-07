package Area::Polygon;
use strict;

use Math::Trig qw(:pi acos);
use Area::Polygon::Matrix;
use Area::Triangle;
use Area::Polygon::LineSegment;
use Area::Polygon::Vertex;
use Area::Polygon::IndexTrapezoidMap;
use Area::Polygon::Line;

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
        for (($args{p0}, $args{p1}, $args{p2})) {
            $state = $res->add_point($_);
            last if $state;
        }
        $res = undef if $state;
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
            my $vertex = Area::Polygon::Vertex->new(
                index => scalar @$vertices,
                point => $pt);
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
    my ($self, $idx) = @_;
    $self->vertex($idx)->point;
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

# calculate spin direction
# This method is not working well.
# I realize that first triangle center may not be in internal point of polygon.
sub calculate_spin_direction {
    my $self = shift;

    my $res;
    if ($self->vertex_count > 2) {
        my @center = (0, 0);
        for (0 .. 2) {
            $center[0] += $self->point($_)->[0];
            $center[1] += $self->point($_)->[1];
        }
        @center = map { $_ / 3 } @center;
        my $total_angles = 0;
        for (0 .. $self->vertex_count - 1) {
            my @points = (
                $self->point($_),
                $self->point(($_ + 1) % $self->vertex_count)
            );
            my @dirs = map {
                my @tmp_pt = ($_->[0] - $center[0], $_->[1] - $center[1]); 
                my $length = 0;
                for (@tmp_pt) {
                    $length += $_ ** 2;
                }
                $length **= 0.5;
                @tmp_pt = map { 
                    my $tmp_val = $_ / $length;
                    $tmp_val = 1 if $tmp_val > 1;
                    $tmp_val = -1 if $tmp_val < -1;
                } @tmp_pt;
                $tmp_pt[0] = 0 if $tmp_pt[1] == 1 or $tmp_pt[1] == -1;
                $tmp_pt[1] = 0 if $tmp_pt[0] == 1 or $tmp_pt[0] == -1;
                \@tmp_pt;
            } @points; 
            my @angles = map {
                my $res = acos($_->[0]);  
                $res = pi2 - $res if ($_->[1] < 0);
            } @dirs; 
            $total_angles += $angles[1] - $angles[0];
        }
         
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



# calculate monotone indices
sub monotone_indices {
    my $self = shift;
    my $indices = $self->create_sorted_vert_indices;
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
sub monotone_mountain_indices {
    my $self = shift;
    my $indices = $self->create_sorted_vert_indices;
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

sub lines_from_vert_index {
    my ($self, $idx) = @_;
    {
        prev => $self->line($idx - 1),
        next => $self->line($idx)
    };
}

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
    my $lines = $self->lines_from_vert_index($vert_idx);

    my @dirs = (
        $lines->{prev}->direction,
        $lines->{next}->direction
    ); 
    
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

# triangulation
sub triangulation
{
    my $self = shift;
    my $monotonized = $self->_monotonize; 

    my @triangles;
    if ($monotonized) {
        my $triangle_indices;
        $triangle_indices = $self->_triangulation_indices($monotonized);
        
        for (@$triangle_indices) {
            my $p1 = $self->point($_->[0]);
            my $p2 = $self->point($_->[1]);
            my $p3 = $self->point($_->[2]);

            push @triangles, Area::Triangle->new(
                x1 => $p1->[0],
                y1 => $p1->[1],
                x2 => $p2->[0],
                y2 => $p2->[1],
                x3 => $p3->[0],
                y3 => $p3->[1]);
        }
    }
   \@triangles;
}


sub _triangulation_indices
{

}


sub _monotonize
{

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
