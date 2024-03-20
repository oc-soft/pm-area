package Area::Polygon;
use strict;

use Dcel;
use Dcel::Operation;
use Area::Polygon::Matrix;
use Area::Triangle;
use Area::Polygon::Dcel;
use Area::Polygon::LineSegmentList;
use Area::Polygon::LineSegment;

our $a, $b;

# construct polygon
sub new
{
    my $class = shift;
    my %args = @_;
    my $res;
    if ($args{p0} && $args{p1} && $args{p2}) {
        
        $res = bless {}, $class;
        $res->{coords} = [];
        
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
    my $coords = $self->{coords};
    my $res = 0;
    for (@points) {
        my $pt = $_;
        if (scalar(@$pt) > 1) {
            push @$coords, $pt;
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

    scalar @{$self->{coords}};
}

sub point
{
    my ($self, $idx) = @_;
    $self->{coords}->[$idx];
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
    my ($self, $monotonized) = @_;

    my @triangle_indices;
    for (@{$monotonized->{monotone_faces}}) {
        my $start_edge;
        Dcel::Operation->for_each_next($_->edge,
            sub {
                my $edge = shift;
                if ($start_edge) {
                    my $edge_point;
                    my $start_edge_point;
                    $edge_point = $edge->origin->data->{point};
                    $start_edge_point = $start_edge->origin->data->{point};
                    $start_edge = $edge
                        if $edge_point->[1] < $start_edge_point->[1];
                } else {
                    $start_edge = $edge;
                }
                0;
            });
        my @indices; 
        Dcel::Operation->for_each_next($start_edge,
            sub {
                my $edge = shift;
                if ($start_edge != $edge) {
                    push @indices, $edge->origin->data->{index};
                }
                0;
            });
         
        my @face_triangle_indices;
        for (0 .. scalar(@indices) - 1) {
            push @face_triangle_indices, [
                $start_edge->origin->data->{index},
                $indices[$_], $indices[$_ + 1]
            ];
        }
        push @triangle_indices, \@face_triangle_indices; 
    }
    \@triangle_indices;
}



sub _monotonize
{
    my $self = shift;
    
    my $ref;
    my $poly_for_mono = $self->_create_polygon_for_monotonize;
    if ($poly_for_mono) {
        my $dcel_coord = $poly_for_mono->_create_dcel_coord;

        my $coord_idx = $dcel_coord->{coord_idx};
        my $dcel = $dcel_coord->{dcel};
        my $start_edge = $dcel_coord->{edge};
        my $vertices = $dcel_coord->{vertices};

        my @mono_faces = ($start_edge->face);

        for (@$coord_idx) {
            my $horizon_ori = $_->{coord};
            my $vert_idx = $_->{index};
            my $vertex = $vertices->[$vert_idx];
            my $edge = Area::Polygon::Dcel::find_edge_from_vertex(
                $start_edge->face, $vertex);
            my $cross_edges = $self->_find_cross_edges($edge);
            if (scalar @$cross_edges > 1) {
                my $to_edge = $edge->prev;
                $dcel->split_face(
                    e1 => $to_edge,
                    e2 => $start_edge->prev);
                $start_edge = $to_edge->next->twin;
                push @mono_faces, $start_edge->face;
            }
        }
        $ref = {
            monotone_faces => \@mono_faces,
            dcel => $dcel,
            polygon => $poly_for_mono
        }; 
    }
    $ref;
}

sub _find_cross_edges {
    my ($self, $edge) = @_;


    my $pt = $edge->origin->data;
   
    my $y = $pt->{point}->[1];

    my @cross_edges;
    my $start_edge = $edge;

    Dcel::Operation->each_edge_next($edge, sub {
        my $edge = shift;
        if ($start_edge != $edge) {
            my @pt = (
                $edge->origin->data,
                $edge->twin->origin->data
            );
            if ($pt[0]->{point}->[1] > $pt[1]->{point}->[1]) {
                if ($pt[0]->{point}->[1] >= $y && $y > $pt[1]->{point}->[1]) {
                    push @cross_edges, $edge;
                }
            } else {
                if ($pt[1]->{point}->[1] > $y && $y >= $pt[0]->{point}->[1]) {
                    push @cross_edges, $edge;
                }
            }
        }
        0;
    });
    \@cross_edges;
}


sub _create_polygon_for_monotonize
{
    my $self = shift;
    my $res;
    if ($self->vertex_count > 2) {
        my $line_segs = $self->_create_line_segments;

        my $radians = $line_segs->all_directions_as_radian;

        if (scalar(@$radians) == $self->vertex_count) {
            my @sorted = sort @$radians;
            my @rads;
            for (@sorted) {
                if (scalar(@rads) == 0) {
                    push @rads, $_;
                } elsif ($rads[-1] != $_) {
                    push @rads, $_;
                    last;
                }
            }
            if (scalar(@rads) > 1) {
                my $rotation = ($rads[0] + $rads[1]) / 2;
                my $cos_val = cos(-$rotation);
                my $sin_val = sin(-$rotation);

                my $mat = Area::Polygon::Matrix->new(
                    a => $cos_val, c => -$sin_val,
                    b => $sin_val, d => $cos_val);
                my @initial_points;
                for (0 .. 2) {
                    push @initial_points, $mat->apply($self->point($_));
                } 

                $res = Area::Polygon->new(
                    p0 => $initial_points[0],
                    p1 => $initial_points[1],
                    p2 => $initial_points[2]);
                for (3 .. $self->vertex_count - 1) {
                    $res->add_point($mat->apply($self->point($_))); 
                }
                $res->{rotation} = $rotation;
            }
        }
    }
    $res;
}


sub _create_line_segments
{
    my $self = shift;
    my $res = Area::Polygon::LineSegmentList->new; 
   
    for (0 .. $self->vertex_count - 1) {
        my $p1_idx = $_;
        my $p2_idx = ($_ + 1) % $self->vertex_count;
        my $p1 = $self->point($p1_idx);
        my $p2 = $self->point($p2_idx);

        my $line_seg = Area::Polygon::LineSegment->new(
            p1 => $p1,
            p2 => $p2); 
        $res->add_line($line_seg);
    }
    $res; 
}


sub _create_dcel_coord
{
    my $self = shift;
    my $coord_idx = $self->_sort_by_y_axis;

    my %res;
    if ($coord_idx) {
        my $dcel = Dcel->new;
        my $start_pt_idx = $coord_idx->[0];

        my @vertices = (undef) x $self->vertex_count;
        my @initial_points;
        for (0 .. 2) { 
            my $idx = ($start_pt_idx->{index} + $_) % $self->vertex_count;
            push @initial_points, {
                point => $self->point($idx),
                index => $idx
            };
        }
        my $edge = $self->register_initial_triangle(
            $dcel, \@vertices, @initial_points);
        my $edge_ptr = $edge;
        for (3 .. $self->vertex_count - 1) { 
            my $idx = ($start_pt_idx->{index} + $_) % $self->vertex_count;
            $edge_ptr = $self->_append_vertex_into_dcel($dcel, \@vertices,
                $edge_ptr, {
                    point => $self->point($idx),
                    index => $idx
                });
        }
        $res{dcel} = $dcel;
        $res{edge} = $edge;
        $res{vertices} = \@vertices;
        $res{coord_idx} = $coord_idx;
    }
    \%res; 
}

# register initial triangle
sub register_initial_triangle
{
    my ($self, $dcel, $vertices, @points) = @_;

    my $edge = $dcel->create_triangle; 
   
    my $idx = 0;
    Dcel::Operation->each_edge_next($edge, sub {
        my $edge = shift;
        $self->bind_vertex($vertices, $edge, $points[$idx]);
        $idx++;
        0;
    }); 
    $edge;
}

# append vertex into dcel 
sub _append_vertex_into_dcel
{
    my ($self, $dcel, $vertices, $edge, $pt) = @_;

    $dcel->split_vertex(
        e1 => $edge,
        e2 => $edge->next->twin);
    
    $self->bind_vertex($vertices, $edge->next, $pt);
    $edge->next;
}

sub bind_vertex
{
    my ($self, $vertices, $edge, $pt) = @_;

    $edge->origin->set_data($pt);
    $vertices->[$pt->{index}] = $edge->origin;
}


sub _sort_by_y_axis
{
    my $self = shift;
    my $coords = $self->{coords};
    $self->_sort_by_y_axis_0($coords);
}

sub _sort_by_y_axis_0
{
    my $self = shift;
    my $coords = shift; 

    my @coord_indices;

    for (0 .. scalar(@$coords) - 1) {
        push @coord_indices, { 
            index => $_, 
            coord => $coords->[$_]
        };
    }
    @coord_indices = sort { 
        my $tmp_val = $a->{coord}[1] - $b->{coord}[1];
        if ($tmp_val == 0) {
            $tmp_val = $a->{coord}[0] - $b->{coord}[0];
        }
        $tmp_val;
    } @coord_indices;

    my $res;
    if (scalar(@$coords) == scalar(@coord_indices)) {
        $res = \@coord_indices;
    }
    $res;    
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
