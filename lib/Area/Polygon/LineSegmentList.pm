package Area::Polygon::LineSegmentList;
use strict;

sub new
{
    my $class = shift;

    my $res = bless {}, $class;

    $res->{lines} = [];

    $res;
}


# add some line segments
sub add_line
{
    my $self = shift;
    
    push @{$self->{lines}}, @_;
}

# get a line
sub line
{
    my ($self, $idx) = @_;
    $self->{lines}->[$idx];
}

# get line segment count
sub count
{
    my $self = shift;
    scalar @{$self->{lines}};
}

# get all directions
sub all_directions
{
    my $self = shift;
    my @directions;
    for (@{$self->{lines}}) {
        my $direction = $_->direction; 
        if ($direction) {
            push @directions, $direction;
        }
    }
    \@directions;
}

sub all_directions_as_radian
{
    use Math::Trig;
    my $self = shift;
    my @directions = map {
        my $cos = $_->[0];
        if ($cos > 1) {
            $cos = 1;
        } elsif ($cos < -1) {
            $cos = -1;
        } 
        acos $cos; 
    } @{$self->all_directions};
    \@directions;
}
1;
__END__

=pod

=head1 Area::Polygon::LineSegmentList - polygon line segment list

It manages some line segments. It also has some utility functions.



=cut

# vi: se ts=4 sw=4 et:
