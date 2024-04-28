package Area::Bezier::Cubic;
use strict;

# create instance
sub new {
    my ($class, %args) = @_;

    my $res;
    if (defined $args{p1} && defined $args{p2}
        && defined $args{c1} && defined $args{c2}) {
        my $tolerance = 1e-5;
        $tolerance = $args{tolerance} if defined $args{tolerance};
        $res = bless {
            p1 => $args{p1},
            p2 => $args{p2},
            c1 => $args{c1},
            c2 => $args{c2},
            tolerance => $tolerance
        }, $class; 

    }
    
    $res;
}

# p1
sub p1 {
    my ($self, $p1) = @_;
    my $res = $self->{p1};
    $self->{p1} = $p1 if defined $p1;
    $res;
}

# p2 
sub p2 {
    my ($self, $p2) = @_;
    my $res = $self->{p2};
    $self->{p2} = $p2 if defined $p2;
    $res;
}

# control point 1
sub c1 {
    my ($self, $c1) = @_;
    my $res = $self->{c1};
    $self->{c1} = $c1 if defined $c1;
    $res;
}

# control point 2
sub c2 {
    my ($self, $c2) = @_;
    my $res = $self->{c2};
    $self->{c2} = $c2 if defined $c2;
    $res;
}

1;
# vi: se ts=4 sw=4 et:
