package Area::Polygon::Vertex;

use strict;

# create instance
sub new {

    my $class = shift;
    my %args = @_;

    my $res = bless {}, $class;

    $res->index($args{index});
    $res->point($args{point}); 
    
    $res;
}


# index
sub index {
    my $self = shift;
    $self->{index} = $_[0] if defined $_[0];
    $self->{index};
}

# point
sub point {
    my $self = shift;
    $self->{point} = $_[0] if defined $_[0];
    $self->{point};
}

1;
__END__


# vi: se ts=4 sw=4 et:
