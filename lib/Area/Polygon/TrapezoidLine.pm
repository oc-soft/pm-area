package Area::Polygon::TrapezoidLine;

use strict;

# create trapezoid line
sub new {
    my $class = shift;
    my $res = bless {}, $class;

    $res;
}

# coordinate
sub coordinate {

    my $self = shift;
    
    if (defined $_[0]) {
        $self{coordinate} = $_[0];
    }
    $self{coordinate};
}

1;
__END__

# vi: se ts=4 sw=4 et:
