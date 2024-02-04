package Area::Triangle;
use Moose;

has ['x1', 'y1', 'x2', 'y2', 'x3', 'y3' ] => (
    is => 'ro',
    isa => 'Num',
    required => 1,
);

# calculate center coordinate
sub center
{
    my $self = shift;
    {
        x => ($self->{x1} + $self->{x2} + $self->{x3}) / 3,
        y => ($self->{y1} + $self->{y2} + $self->{y3}) / 3
    }
}

# calculate area
sub area
{
    my $self = shift;

    my @av = (
        $self->{x2} - $self->{x1},
        $self->{y2} - $self->{y1}
    );
    my @bv = (
        $self->{x3} - $self->{x1},
        $self->{y3} - $self->{y1}
    );

    ($av[0] * $bv[1] - $av[1] * $bv[0]) / 2;
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
