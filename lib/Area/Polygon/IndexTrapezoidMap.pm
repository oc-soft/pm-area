package Area::Polygon::IndexTrapezoidMap;

use strict;

# create instance
sub new {
    my ($class, %args) = @_;

    my $res;
    if ($args{count_of_lines}) {
        my @lines;
        for (0 .. $args{count_of_lines} - 1) {
            push @lines, [];
        }
        $res = bless {
            lines => \@lines
        }, $class;
    }
    $res;
}


# add trapezoid
sub add_trapezoid {
    my ($self, %args) = @_;

    if (defined $args{index} && $args{trapz_line}) { 
        push @{$self->{lines}->[$args{index}]}, $args{trapz_line};
    }
}

# get trapezoid lines
sub trapezoid_lines {
    my ($self, %args) = @_;
    $self->{lines}->[$args{index}];
}


sub trapezoid_line {
    my ($self, %args) = @_;
    my $trapz_lines = $self->trapezoid_lines(index => $args{line_index});
    $trapz_lines->[$args{index}];
}

sub trapezoid_line_count {
    scalar @{trapezoid_lines(@_)};
}


sub find_trapezoid_index {
    my ($self, %args) = @_;
    my $trapz_lines = trapezoid_lines @_;

    my $res;
    if ($trapz_lines && $args{coordinate_index}) {
        my $l = 0;
        my $coord_index = $args{coordinate_index};
        my $r = (scalar @$trapz_lines) - 1;
        while ($l <= $r) {
            my $idx = POSIX::floor(($l + $r) / 2);
            my $trapz_index = $trapz_lines->[$idx]->{coordinate_index}; 
            if ($trapz_index < $coord_index) {
                $l = $idx + 1;
            } elsif ($trapz_index > $coord_index) {
                $r = $idx - 1;
            } else { # $trapz_index == $coord_index
                $res = $idx;
                last; 
            } 
        }
    }
    $res;
}

1;
__END__

# vi: se ts=4 sw=4 et:
