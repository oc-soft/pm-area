package Area::Path;

use strict;
use Scalar::Util qw(blessed);
use Area::Polygon;
use Area::Bezier::Cubic;
use Area::Bezier::Quadratic;
use Area::Arc;

# constructor
sub new {
    
    my $class = shift;
    my $res = bless {}, $class;
    $res->{commands} = [];

    $res;
}

# duplicate path
sub clone {
    my $self = shift;
    my $res = new blessed($self);

    for (0 .. $self->command_count - 1) {
        my $command = $self->command($_);
        my %cloned = %$command;
        push @{$res->{commands}}, \%cloned;
    }
    $res;
}


# translate
sub translate {
    my ($self, $x, $y) = @_;
    for (0 .. $self->command_count - 1) {
        $self->translate_command($_, $x, $y);
    } 
}

# scale
sub scale {
    my ($self, $x, $y) = @_;
    for (0 .. $self->command_count - 1) {
        $self->scale_command($_, $x, $y);
    } 
}

# rotate 
sub rotate {
    my ($self, $rot) = @_;
    for (0 .. $self->command_count - 1) {
        $self->rotate_command($_, $rot);
    } 
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
       $cmd->{string}->($cmd);
    }
}

# traslate a command 
sub translate_command {
    my ($self, $cmd_idx, $x, $y) = @_;
    $x = 0 if !defined $x;
    $y = 0 if !defined $y;
    if ($x || $y) {
        my $cmd = $self->command($cmd_idx);
        if (defined $cmd) {
            if ($cmd->{command} =~ /M|L/) {
                $cmd->{x} += $x;
                $cmd->{y} += $y;
            } elsif ($cmd->{command} eq 'C') {
                for ((1, 2, '')) {
                    $cmd->{"x$_"} += $x;
                    $cmd->{"y$_"} += $y;
                }
            } elsif ($cmd->{command} eq 'Q') {
                for ((1, '')) {
                    $cmd->{"x$_"} += $x;
                    $cmd->{"y$_"} += $y;
                }
            } elsif ($cmd->{command} eq 'A') {
                $cmd->{x} += $x;
                $cmd->{y} += $y;
            }
        }
    }
}

# scale a command
sub scale_command {
    my ($self, $cmd_idx, $x, $y) = @_;
    $x = 1 if !defined $x;
    $y = 1 if !defined $y;
    if ($x != 1 || $y != 1) {
        my $cmd = $self->command($cmd_idx);
        if (defined $cmd) {
            if ($cmd->{command} =~ /M|L/) {
                $cmd->{x} *= $x;
                $cmd->{y} *= $y;
            } elsif ($cmd->{command} eq 'C') {
                for ((1, 2, '')) {
                    $cmd->{"x$_"} *= $x;
                    $cmd->{"y$_"} *= $y;
                }
            } elsif ($cmd->{command} eq 'Q') {
                for ((1, '')) {
                    $cmd->{"x$_"} *= $x;
                    $cmd->{"y$_"} *= $y;
                }
            } elsif ($cmd->{command} eq 'A') {
                $cmd->{rx} *= $x;
                $cmd->{ry} *= $y;
                $cmd->{x} *= $x;
                $cmd->{y} *= $y;
            }
        }
    }
}

# rotate a command
sub rotate_command {
    my ($self, $cmd_idx, $rot) = @_;
    $rot = 0 if !defined $rot;
    my $cos = cos($rot);

    if ($cos != 1) {
        my $sin = sin($rot);
        sub xrot {
            my ($cos, $sin, $x, $y) = @_;
            $x * $cos - $y * $sin; 
        }
        sub yrot {
            my ($cos, $sin, $x, $y) = @_;
            $x * $sin + $y * $cos;
        } 
        my $cmd = $self->command($cmd_idx);
        if (defined $cmd) {
            if ($cmd->{command} =~ /M|L/) {
                my @pt = ($cmd->{x}, $cmd->{y});
                $cmd->{x} = xrot($cos, $sin, @pt);
                $cmd->{y} = yrot($cos, $sin, @pt);
            } elsif ($cmd->{command} eq 'C') {
                for ((1, 2, '')) {
                    my @pt = ($cmd->{"x$_"}, $cmd->{"y$_"});
                    $cmd->{"x$_"} = xrot($cos, $sin, @pt);
                    $cmd->{"y$_"} = yrot($cos, $sin, @pt);
                }
            } elsif ($cmd->{command} eq 'Q') {
                for ((1, '')) {
                    my @pt = ($cmd->{"x$_"}, $cmd->{"y$_"});
                    $cmd->{"x$_"} = xrot($cos, $sin, @pt);
                    $cmd->{"y$_"} = yrot($cos, $sin, @pt);
                }
            } elsif ($cmd->{command} eq 'A') {
                my @pt = ($cmd->{x}, $cmd->{y});
                $cmd->{x} = xrot($cos, $sin, @pt);
                $cmd->{y} = yrot($cos, $sin, @pt);

                if ($cmd->{rx} != $cmd->{ry}) {
                    if (abs($sin) == 1) {
                        my $tmp_val = $cmd->{rx};
                        $cmd->{rx} = $cmd->{ry};
                        $cmd->{ry} = $tmp_val;
                    } else {
                        my @r = ($cmd->{rx}, $cmd->{ry});
                        $cmd->{rx} = abs(xrot($cos, $sin, @r));  
                        $cmd->{ry} = abs(xrot($cos, $sin, @r));  
                    }
                }
            }
        }
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
        string => sub {
            my $cmd = shift;
            join ' ', $cmd->{command}, $cmd->{x}, $cmd->{y};
        }
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
        string => sub {
            my $cmd = shift;
            join ' ', $cmd->{command}, $cmd->{x}, $cmd->{y};
        }
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
        string => sub {
            my $cmd = shift;
            join ' ', $cmd->{command},
                $cmd->{x1}, $cmd->{y1},
                $cmd->{x2}, $cmd->{y2},
                $cmd->{x}, $cmd->{y};
        }
    };
}


# add quadratic bezier to command
sub quadratic_bezierto {
    my ($self, $x1, $y1, $x, $y) = @_;
    push @{$self->{commands}}, {
        command => 'Q',
        x1 => $x1, y1 => $y1, 
        x => $x, y => $y,
        string => sub {
            my $cmd = shift;
            join ' ', $cmd->{command},
                $cmd->{x1}, $cmd->{y1},
                $cmd->{x}, $cmd->{y};
        }
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
        x_axis_rotation => $x_axis_rotation,
        large_arc_flag => $large_arc_flag,
        sweep_flag => $sweep_flag,
        x => $x, y => $y,
        string => sub {
            my $cmd = shift;
            join ' ', $cmd->{command},
                $cmd->{rx}, $cmd->{ry},
                $cmd->{x_axis_rotation}, $cmd->{large_arc_flag},
                $cmd->{sweep_flag},
                $cmd->{x}, $cmd->{y};
        }
    };
}

# add close path command
sub close {
    my $self = shift;
    push @{$self->{commands}}, {
        command => 'Z',
        string => sub {
            'Z'
        }
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

# convert lines and svg element
sub covert_lines_and_svg_element {
    my ($self, $last_cmd, $cmd) = @_;

    my %res;
    if ($cmd->{command} =~ /L|C|Q/) {
        $res{points} = [
            [
                $last_cmd->{x},
                $last_cmd->{y},
            ],
            [
                $cmd->{x},
                $cmd->{y}
            ]
        ]  
    }
    if ($cmd->{command} eq 'C') {
        $res{command} = Area::Bezier::Cubic->new(
            p1 => [ $last_cmd->{x}, $last_cmd->{y} ],
            p2 => [ $cmd->{x}, $cmd->{y} ],
            c1 => [ $cmd->{x1}, $cmd->{y1} ],
            c2 => [ $cmd->{x2}, $cmd->{y2} ]
        );
    } elsif ($cmd->{command} eq 'Q') {
        $res{command} = Area::Bezier::Quadratic->new(
            p1 => [ $last_cmd->{x}, $last_cmd->{y} ],
            p2 => [ $cmd->{x}, $cmd->{y} ],
            c => [ $cmd->{x1}, $cmd->{y1} ],
        );
    } elsif ($cmd->{command} eq 'A') {
        my $arc = Area::Arc->new(
            x1 => $last_cmd->{x},
            y1 => $last_cmd->{y},
            angle => $cmd->{x_axis_rotation},  
            large_arc_flag => $cmd->{large_arc_flag}, 
            sweep_flag => $cmd->{sweep_flag},
            rx => $cmd->{rx},
            ry => $cmd->{ry},
            x2 => $cmd->{x},
            y2 => $cmd->{y}
        );
        $res{command} = $arc;

        my $center_param = $arc->center_parameter; 
        $res{points} = [
            [
                $last_cmd->{x},
                $last_cmd->{y},
            ],
            [
                $center_param->{cx},
                $center_param->{cy}
            ],
            [
                $cmd->{x},
                $cmd->{y}
            ]
        ]; 
    }
    \%res;
}


# convert some polygons and some svg elements
sub polygons_and_svg_elements {
    my $self = shift;
    my $polygon_commands = $self->create_polygon_commands;
    my @res;
    for (@$polygon_commands) {
        my $commands = $_;
        if (scalar(@$commands) > 2) {
            my @svg_commands;
            my @line_commands = (
                $self->covert_lines_and_svg_element($_->[0], $_->[1]),
                $self->covert_lines_and_svg_element($_->[1], $_->[2]),
            );
            my %poly_param = (
                p0 => $line_commands[0]->{points}->[0]
            );
            for (1 .. @{$line_commands[0]->{points}} - 1) {
                $poly_param{"p$_"} = $line_commands[0]->{points}->[$_];
            }
            my $idx_offset = @{$line_commands[0]->{points}};
            for (1 .. @{$line_commands[1]->{points}} - 1) {
                my $pt_idx = $_ + $idx_offset - 1;
                $poly_param{"p$pt_idx"} = $line_commands[1]->{points}->[$_];
            }
            for (@line_commands) {
                push @svg_commands, $_->{command} if defined $_->{command};
            }
            my $polygon = Area::Polygon->new(%poly_param);
            for (3 .. scalar(@$commands) - 1) {
                my $line_command = $self->covert_lines_and_svg_element(
                    $commands->[$_ - 1], $commands->[$_]);
                push @svg_commands, $line_command->{command}
                    if defined $line_command->{command};
                for (1 .. @{$line_command->{points}} - 1) {
                    $polygon->add_point($line_command->{points}->[$_]);
                }
            }
            push @res, {
                polygon => $polygon,
                svg_elements => \@svg_commands
            }; 
        }
    }
    \@res;
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
