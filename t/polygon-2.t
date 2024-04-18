use strict;

use Test::Simple tests => 8; 
use Area::Polygon;


# test constructor
sub construct {
    my @points = (
        [0, 0],
        [1, 1],
        [-1, 1],
        [-1, 0]
    );
    
    my $poly = Area::Polygon->new(
        p0 => $points[0],
        p1 => $points[1],
        p2 => $points[2],
        p5 => $points[3] 
    );


    
    ok($poly->vertex_count == 4, 'expect the polygon has 4 vertices.');
    
    my $pt = $poly->point(3);
    ok($pt->[0] == $points[3]->[0] && $pt->[1] == $points[3]->[1],
        'expect last coodinate is match p5 coordinate');
    
}

# test clockwise
sub clockwise {

    my $poly = Area::Polygon->new(
        p0 => [0, 0],
        p1 => [1, 1],
        p2 => [-1, 1]
    );

    ok($poly->is_clockwise == 0, 'expect clockwise test is 0');
}

# test polygon has same points
sub check_having_same_points {
    my $poly = Area::Polygon->new(
        p0 => [0, 0.01],
        p1 => [1, 1.0051],
        p2 => [1, 1.0052],
        tolerance => 1E-2
    );

    ok($poly->find_same_points, 'expect same point test is 1');
    $poly = Area::Polygon->new(
        p0 => [0, 0.01],
        p1 => [1, 1.0051],
        p2 => [1, 1.0052]
    );

    ok(!$poly->find_same_points, 'expect same point test is 0');
}

sub directions {

    my $poly = Area::Polygon->new(
        p0 => [1, 1],
        p1 => [-1, 1],
        p2 => [-1, -1],
        p3 => [1, -1]
    );
    

    my $dirs = $poly->line_directions;

    my $res = scalar(keys(%$dirs)) == 4;
    if ($res) {
        for (keys %$dirs) {
            my $dir_array = $dirs->{$_};
            
            for (@$dir_array) {
                my $len = ($_->[0] ** 2 + $_->[1] ** 2) ** 0.5;
                $res = 1E-10 > abs($len - 1);
                last if !$res;
            }
            last if !$res;
        }
    }
    ok($res, 'expected the polygon has 4 directions');
}

sub rounded_directions {

    my $poly = Area::Polygon->new(
        p0 => [1, 1],
        p1 => [-1, 1 + 1e-10],
        p2 => [-1 + 1e-10, -1],
        p3 => [1, -1],
        tolerance => 1e-2
    );
    
    my %keys; 
    
    $keys{-1, 0} = [-1, 0];
    $keys{0, -1} = [0, -1];
    $keys{1, 0} = [1, 0];
    $keys{0, 1} = [0, 1];

    my $dirs = $poly->rounded_directions;

    my $res = scalar(keys(%$dirs)) == 4;
    if ($res) {
        for (keys %keys) {
            $res = defined $dirs->{$_};
            last if !$res;
        }
    }
    ok($res, 'expected the polygon has 4 square directions');
}

sub rounded_directions_y_positive {

    my $poly = Area::Polygon->new(
        p0 => [1, 1],
        p1 => [-1, 1 + 1e-10],
        p2 => [-1 + 1e-10, -1],
        p3 => [1, -1 - 1e-5],
        tolerance => 1e-2
    );
    
    my %keys; 
    
    $keys{1, 0} = [1, 0];
    $keys{0, 1} = [0, 1];

    my $dirs = $poly->rounded_directions_y_positive;

    my $res = scalar(keys(%$dirs)) == scalar(keys(%keys));
    if ($res) {
        for (keys %keys) {
            $res = defined $dirs->{$_};
            last if !$res;
        }
    }
    ok($res, 'expected the polygon has 2 square directions');
}




construct;
clockwise;
check_having_same_points;
directions;
rounded_directions;
rounded_directions_y_positive;
__END__

# vi: se ts=4 sw=4 et:
