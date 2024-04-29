package Area::Triangle;
use Moose;

has ['x1', 'y1', 'x2', 'y2', 'x3', 'y3' ] => (
    is => 'ro',
    isa => 'Num',
    required => 1,
);


# get first moment of area
sub first_moment_of_area
{
    my $area = area(@_);
    my $center = center(@_); 

    {
        sx => $center->{x} * $area,
        sy => $center->{y} * $area
    }
}

# calculate center coordinate
sub center
{
    my $self = shift;
    {
        x => ($self->x1 + $self->x2 + $self->x3) / 3,
        y => ($self->y1 + $self->y2 + $self->y3) / 3
    }
}

# get point sequence
sub points {
    my $self = shift;
    [ 
        [ $self->x1, $self->y1 ],
        [ $self->x2, $self->y2 ],
        [ $self->x3, $self->y3 ]
    ];
}

# calculate bounds
sub bounds {
    my $self = shift;
    my @pt_x = sort { 
        our $a;
        our $b;
        $a->[0] <=> $b->[0];
    } @{$self->points}; 
    my @pt_y = sort {
        our $a;
        our $b;
        $a->[1] <=> $b->[1];
    } @{$self->points};
    [ $pt_x[0][0], $pt_y[0][1], $pt_x[-1][0], $pt_y[-1][1] ];
}

# calculate signed area
sub signed_area
{
    my $self = shift;

    my $area = 0;
    my $points = $self->points;
    for (0 .. @$points - 1) {
        my $pt0 = $points->[$_ - 1];
        my $pt1 = $points->[$_];
        $area += ($pt1->[0] - $pt0->[0]) * ($pt0->[1] + $pt1->[1]) / 2;
    }
    $area;
}

# calculate area
sub area {
    my $self = shift;
    abs($self->signed_area);
}
1;

__END__

=pod

=head1 NAME

Area::Triangle - area gemetoric function utility

Simple triangle polygon to solve center and area.

=head1 SYNOPSIS

 use Area::Triangle;
 use Math::Trig ':pi';
 # create new instance of triangle (x1, y1), (x2, y2) and (x3, y3). 
 $triangle = Area::Triangle->new(
     x1 => -1, y1 => 0,
     x2 => 1, y2 => 0,
     x3 => 0, y3 => cos(pi / 3));

=head1 OBJECT-ORIENTED INTERFACE


=head2 new

create a triangle


     use Area::Triangle;
     $triangle = Area::Triangle->new(
         x1 => -10, y1 => 0,
         x2 => 10, y2 => 0,
         x3 => 0, y3 => 10);

=head2 first_moment_of_area

calculate first moment of area

 my $fmoa = $triangle->first_moment_of_area();
 
 print 'sx:' . $fmoa->{sx} . "\n";
 print 'sy:' . $fmoa->{sy} . "\n";


=head2 center

calculate center coordinate


 my $center = $triangle->center();
    
 print 'x:' . $center->{x} . "\n"; 
 print 'y:' . $center->{y} . "\n";

=head2 area

caclulate area

 my $area = $triangle->area();

 print 'area: ' $area . "\n";
     
=cut

# vi: se ts=4 sw=4 et:
