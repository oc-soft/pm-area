package Area::Polygon::Line;
use strict;

# create line
sub new {
    my ($class, %args) = @_;

    my $res;
    if ($args{p1} && $args{p2}) {
        $res = bless {}, $class;
        $res->p1($args{p1});
        $res->p2($args{p2}); 
    }
    $res;
}


# point 1
sub p1 {
    my ($self, $pt) = @_;
    if (defined $pt) {
        $self->{p1} = $pt;
    }
    $self->{p1};
}

# point 2
sub p2 {
    my ($self, $pt) = @_;
    if (defined $pt) {
        $self->{p2} = $pt;
    }
    $self->{p2};
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

# x coordinate
sub x_coords {
    my $self = shift;
    [ $self->p1->[0], $self->p2->[0] ];
}

# y coordinate
sub y_coords {
    my $self = shift;
    [ $self->p1->[1], $self->p2->[1] ];
}


# calculate intersection
sub intersection {
    my ($class, $l1, $l2) = @_;

    my @x_coords = (@{$l1->x_coords}, @{$l2->x_coords});
    my @y_coords = (@{$l1->y_coords}, @{$l2->y_coords});

    # we resolve intersection from following equation
    # Pi = Xm / d, Ym / d
    # d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    my $d = ($x_coords[0] - $x_coords[1]) * ($y_coords[2] - $y_coords[3])
        - ($y_coords[0] - $y_coords[1]) * ($x_coords[2] - $x_coords[3]);

    my $res;
    if ($d != 0) {
        # Xm = xy12 * (x3 - x4) - (x1 - x2) * xy34
        # Ym = xy12 * (y3 - y4) - (y1 - y2) * xy34
        
        # xy12 = x1 * y2 - y1 * x2
        # xy34 = x3 * y4 - y4 * x3
        my $xy12 = $x_coords[0] * $y_coords[1] - $y_coords[0] * $x_coords[1];
        my $xy34 = $x_coords[2] * $y_coords[3] - $y_coords[2] * $x_coords[3];
        my $xm = $xy12 * ($x_coords[2] - $x_coords[3]);
        $xm -= ($x_coords[0] - $x_coords[1]) * $xy34;
        my $ym = $xy12 * ($y_coords[2] - $y_coords[3]);
        $ym -= ($y_coords[0] - $y_coords[1]) * $xy34;
        $res = [
            $xm / $d,
            $ym / $d    
        ];
    }
    $res;
}

1;
# vi: se ts=4 sw=4 et:
