package Area::Polygon::LineSegment;
use strict;

use Area::Polygon::Line;

# create new line segment
sub new
{
    my ($class, %args) = @_;
    my $res;
    if ($args{v1} && $args{v2}) {
        $res = bless {}, $class;
        $res->v1($args{v1});
        $res->v2($args{v2});
    }
    $res; 
}

# duplicate line which share points
sub dup
{
    my $self = shift;
    Area::Polygon::LineSegment->new(v1 => $self->v1, v2 => $self->v2);
}

# caculate distance
sub distance
{
    my $self = shift;
    my $res = 0;

    my $x_coords = $self->x_coords;
    $res += ($x_coords->[0] - $x_coords->[1]) ** 2;
    my $y_coords = $self->y_coords;
    $res += ($y_coords->[0] - $y_coords->[1]) ** 2;
    $res = $res ** 0.5; 
    
    $res;
}

# direction vector
sub direction
{
    my $self = shift;
    my $res;

    my $distance = $self->distance;

    if ($distance > 0) {
        my $x_coords = $self->x_coords;
        my $y_coords = $self->y_coords;
        $res = [
            ($x_coords->[1] - $x_coords->[0]) / $distance,
            ($y_coords->[1] - $y_coords->[0]) / $distance
        ];
        if ($res->[0] > 1) {
            $res->[0] = 1;
            $res->[1] = 0;
        } elsif ($res->[0] < -1) {
            $res->[0] = -1;
            $res->[1] = 0;
        }
        if ($res->[1] > 1) {
            $res->[1] = 1;
            $res->[0] = 0;
        } elsif ($res->[1] < -1) {
            $res->[1] = -1;
            $res->[0] = 0;
        }
    } 
    $res;
}

# normal vector
sub normal {
    my $self = shift;
    my $d = $self->direction;

    my $res;
    if ($d->[0] != 0) {
        $res = [$d->[1], -$d->[0]];
    } else {
        $res = [-$d->[1], $d->[0]]; 
    }
    $res;
}

# convert simple line
sub to_line {
    my $self = shift;
    Area::Polygon::Line->new(p1 => $self->p1, p2 => $self->p2);
}


# x coordinate
sub x_coords
{
    my $self = shift;
    [ $self->v1->point->[0], $self->v2->point->[0] ];
}

# y coordinate
sub y_coords
{
    my $self = shift;
    [ $self->v1->point->[1], $self->v2->point->[1] ];
}

# v1
sub v1
{
    my $self = shift;
    $self->{v1} = $_[0] if defined $_[0];
    $self->{v1};
}

# v2
sub v2
{
    my $self = shift;
    $self->{v2} = $_[0] if defined $_[0];
    $self->{v2};
}

# p1
sub p1 {
    my $self = shift;
    $self->v1->point;
}

# p2
sub p2 {
    my $self = shift;
    $self->v2->point;
}

1;
__END__

=pod

=head1 Area::Polygon::LineSegment line segement operation

=head2 new

create new line segment

 my $line_seg = Area::Polygon::LineSegment->new(
     p1 => [ 0, 1 ], p2 => [ 1, 0 ]);
     
=head2 length

calculate distance to point

 my $line_seg = Area::Polygon::LineSegment->new(
     p1 => [ 0, 3 ], p2 => [ 4, 0 ]);
 my $length = $line_seg->length;
 # expect length 5 
 print "length $length\n";

 
=head2 direction

calculate direction

 my $line_seg = Area::Polygon::LineSegment->new(
     p1 => [ 1, 2 ], p2 => [ 3, 5 ]);
 my $direction = $line_seg->direction;
 # expect direction [ 1, 1 ] 
 print "direction [ $direction->[0], $direction->[1] ]\n";


=head2 x_coords

get x coordinate array

 my $line_seg = Area::Polygon::LineSegment->new(
     p1 => [ 1, 2 ], p2 => [ 3, 4 ]);
 my $x_coords = $line_seg->x_coords;
 # expect [ 1, 3 ] 
 print "[ $x_cords->[0], $x_coors->[1] ]\n";


=head2 y_coords

get y coordinate array

 my $line_seg = Area::Polygon::LineSegment->new(
     p1 => [ 1, 2 ], p2 => [ 3, 4 ]);
 my $y_coords = $line_seg->y_coords;
 # expect [ 2, 4 ] 
 print "[ $y_cords->[0], $y_coors->[1] ]\n";


=head p1

get p1 coordinate

 my $line_seg = Area::Polygon::LineSegment->new(
     p1 => [ 1, 2 ], p2 => [ 3, 4 ]);
 my $p1 = $line_seg->p1;
 # expect [ 1, 2 ] 
 print "[ $p1->[0], $p1->[1] ]\n";

=head p2

get p1 coordinate

 my $line_seg = Area::Polygon::LineSegment->new(
     p1 => [ 1, 2 ], p2 => [ 3, 4 ]);
 my $p2 = $line_seg->p2;
 # expect [ 3, 4 ] 
 print "[ $p2->[0], $p2->[1] ]\n";

=cut

# vi: se ts=4 sw=4 et:
