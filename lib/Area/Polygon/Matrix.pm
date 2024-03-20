package Area::Polygon::Matrix;

use strict;

sub new {
    my ($class, %args) = @_;

    my $res = bless {}, $class;

    $res->{components} = [
        [1, 0, 0],
        [0, 1, 0]
    ];
    $res->components(%args);
    $res;
}


sub components {
    my ($self, %args) = @_;

    my $components = $self->{components};

    $self->component(row => 0, 
        column => 0,
        value => $args{a}) if defined $args{a};

    $self->component(row => 0, 
        column => 1,
        value => $args{c}) if defined $args{c}; 
      
    $self->component(row => 1, 
        column => 0,
        value => $args{b}) if defined $args{b}; 

    $self->component(row => 1, 
        column => 1,
        value => $args{d}) if defined $args{d}; 

    $self->component(row => 0, 
        column => 2,
        value => $args{tx}) if defined $args{tx}; 
    $self->component(row => 1, 
        column => 2,
        value => $args{ty}) if defined $args{ty}; 
    0;
}

sub component {

    my ($self, %args) = @_;

    my $value;
    $value = $args{value} if defined $args{value};
    my $components = $self->{components};
    my $res = $components->[$args{row}]->[$args{column}];
    $components->[$args{row}]->[$args{column}] = $value if defined $value; 
    $res;
}

sub apply {
    my ($self, $x, $y) = @_;
    
    my @coord;
    push @coord,
        ($self->component(row => 0, column => 0) * $x
            + $self->component(row => 0, column => 1) * $y
            + $self->component(row => 0, column => 2));
    push @coord,
        ($self->component(row => 1, column => 0) * $x
            + $self->component(row => 1, column => 1) * $y
            + $self->component(row => 1, column => 2));
        
    \@coord;
}

1;

# vi: se ts=4 sw=4 et:
