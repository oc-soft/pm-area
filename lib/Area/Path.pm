package Area::Path;

use strict;
use Area::Polygon;

# constructor
sub new {
    
    my $class = shift;
    my $res = bless {}, $class;
    $res->{commands} = [];

    $res;
}

# get command count
sub command_count {
    my $self = shift;
    scalar @{$self->{commands}};
}

# get command    
sub command {
    my ($self, $idx) = @_;

    my $res;
    if (defined $idx) {
        $res = $self->{commands}->[$idx];
    }
    $res;
}

# get command as string
sub command_str {
    my $cmd = command @_;

    if ($cmd) {
       $cmd->{string};
    }
}

# add moveto command
sub moveto {

    my ($self, $x, $y) = @_;    

    push @{$self->{commands}}, $self->create_moveto($x, $y);
}

# create moveto command
sub create_moveto {
    my ($self, $x, $y) = @_;
    {
        command => 'M',
        x => $x,
        y => $y,
        string => "M $x $y"
    };
}

# add line to command
sub lineto {
    my ($self, $x, $y) = @_;
    
    push @{$self->{commands}}, $self->create_lineto($x, $y); 
}


# create lineto command
sub create_lineto {
    my ($self, $x, $y) = @_;
    {
        command => 'L',
        x => $x,
        y => $y,
        string => "L $x $y"
    };
}

# add cubic bezier to command
sub cubic_bezierto {

    my ($self, $x1, $y1, $x2, $y2, $x, $y) = @_;
    push @{$self->{commands}}, {
        command => 'C',
        x1 => $x1, y1 => $y1, 
        x2 => $x2, y2 => $y2,
        x => $x, y => $y,
        string => "C $x1 $y1 $x2 $y2 $x $y"
    };
    
}


# add quadratic bezier to command
sub quadratic_bezierto {
    my ($self, $x1, $y1, $x, $y) = @_;
    push @{$self->{commands}}, {
        command => 'Q',
        x1 => $x1, y1 => $y1, 
        x => $x, y => $y,
        string => "Q $x1 $y1 $x $y"
    };
}

# get last start point command
sub last_start_command {
    
    my $self = shift;
    my $result; 
    for (0 .. $self->command_count - 1) {
        my $command = $self->{commands}->[$self->command_count - 1 - $_];
        if ($command->{command} == 'M') {
            $result = $command;
            last;
        }
    }
    $result;
}

# add elliptical arc command
sub arcto {
    my ($self,
        $rx, $ry,
        $x_axis_rotation,
        $large_arc_flag, $sweep_flag,
        $x, $y) = @_;
    push @{$self->{commands}}, {
        command => 'A',
        rx => $rx, ry => $ry, 
        x_axis_rotaion => $x_axis_rotation,
        large_arc_flag => $large_arc_flag,
        sweep_flag => $sweep_flag,
        x => $x, y => $y,
        string => "A $rx $ry $x_axis_rotation $large_arc_flag $sweep_flag $x $y"
    };
}

# add close path command
sub close {
    my $self = shift;
    push @{$self->{commands}}, {
        command => 'Z',
        string => 'Z'
    };
}

# get last cubic control point
sub last_cubic_control_point {
    my $self = shift;

    my $res;
    if ($self->command_count) {
        my $last_command = @{$self->{commands}}[-1]; 
        if ($last_command->{command} eq 'C') {
            $res = [$last_command->{x2}, $last_command->{y2}];
        } elsif ($last_command->{command} eq 'Z') {
            my $last_start_cmd = $self->last_start_command;
            if ($last_start_cmd) {
                $res = [$last_start_cmd->{x}, $last_start_cmd->{y}]; 
            }
        } else {
            $res = [$last_command->{x}, $last_command->{y}];
        }
    }
    $res;
}

# get last quadratic control point
sub last_quadratic_control_point {
    my $self = shift;

    my $res;
    if ($self->command_count) {
        my $last_command = @{$self->{commands}}[-1]; 
        if ($last_command->{command} eq 'Q') {
            $res = [$last_command->{x1}, $last_command->{y1}];
        } elsif ($last_command->{command} eq 'Z') {
            my $last_start_cmd = $self->last_start_command;
            if ($last_start_cmd) {
                $res = [$last_start_cmd->{x}, $last_start_cmd->{y}]; 
            }
        } else {
            $res = [$last_command->{x}, $last_command->{y}];
        }
    }
    $res;
}


# convert some polygons
sub to_polygons
{
    my $self = shift;
    my $polygon_commands = $self->create_polygon_commands;
    my @res;
    for (@$polygon_commands) {
        my $commands = $_;
        if (scalar(@$commands) > 2) {
            my $polygon = Area::Polygon->new(
                p0 => [$_->[0]->{x}, $_->[0]->{y}],
                p1 => [$_->[1]->{x}, $_->[1]->{y}],
                p2 => [$_->[2]->{x}, $_->[2]->{y}]);
            for (3 .. scalar(@$commands) - 1) {
                $polygon->add_point(
                    [$commands->[$_]->{x}, $commands->[$_]->{y}]);
            }
            push @res, $polygon; 
        }
    }
    \@res;
}


# find start indicies
sub create_polygon_commands
{
    my $self = shift;
    my $mode = 'start';
    my $last_move_command;
    my @res;
    my $commands = []; 
    for (0 .. $self->command_count - 1) {
        my $cmd = $self->command($_);
        if ($mode eq 'start') {
            if ($cmd->{command} eq 'M') {
                $last_move_command = $cmd;
                push @$commands, $cmd;
                $mode = 'draw';
            }
        } elsif ($mode eq 'seek') {
            if ($cmd->{command} ne 'M') {
                if ($cmd->{command} ne 'Z') {
                    push @$commands, $last_move_command;
                    push @$commands, $cmd;
                    $mode = 'draw';
                }
            } else {
                $last_move_command = $cmd;
            }
        } elsif ($mode eq 'draw') {
            if ($cmd->{command} eq 'M') {
                $mode = 'seek';
                $last_move_command = $cmd;
                push @res, $commands;
                $commands = [];
            }
            elsif ($cmd->{command} eq 'Z') {
                push @res, $commands;
                $mode = 'seek';
                $commands = [];
            } else {
                push @$commands, $cmd;  
            }
        }
    }
    if (scalar(@$commands)) {
        push @res, $commands;
    }
    
    \@res; 
}

1;
# vi: se ts=4 sw=4 et:
