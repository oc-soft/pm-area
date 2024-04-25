use strict;
use Test::Simple tests => 7; 
use Math::Trig ':pi';
use Area::Polygon;

our $a, $b;

sub create_rect_param {
    { 
        p0 => [ 0, 0 ],
        p1 => [ 2, 0 ],
        p2 => [ 2, 1 ],
        p3 => [ 0, 1 ]
    };
}

sub create_symmetric_param_1 {

    my %param;
    for (0 .. 11) {
        my @point = (cos(($_ * pi) / 6),  sin(($_ * pi) / 6));
        if (abs(abs($point[0]) - 1) < 1e-5) {
            my $sign = $point[0] <=> 0;
            @point = ($sign * 1, 0);
        }
        if (abs(abs($point[1]) - 1) < 1e-5) {
            my $sign = $point[1] <=> 0 ;
            @point = (0, $sign * 1);
        }
        $param{"p$_"} = \@point;
    }
    \%param;
}

sub create_symmetric_param_2 {
    my ($offset_x, $offset_y) = @_;
    $offset_x = 0 if !defined $offset_x;
    $offset_y = 0 if !defined $offset_y;
    my $params = create_symmetric_param_1;
    for (keys %$params) {
        $params->{$_}->[0] += $offset_x;
        $params->{$_}->[1] += $offset_y;
    }
    $params;
}

sub create_symmetric_param_3 {

    my ($offset_x, $offset_y) = @_;
    $offset_x = 0 if !defined $offset_x;
    $offset_y = 0 if !defined $offset_y;
    
    my @points = (
        [ 1, 0 ],
        [ 1, 1 ],
        [ 2, 2 ],
        [ 0, 4 ],
        [ -2, 2 ],
        [ -1, 1 ],
        [ -1, 0 ],
        [ -1, -1 ],
        [ -2, -2 ],
        [ 0, -4 ],
        [ 2, -2 ],
        [ 1, -1 ],
    );
    my %param;
    for (0 .. $#points) {
        $param{"p$_"} = [
            $points[$_]->[0] + $offset_x,
            $points[$_]->[1] + $offset_y
        ];
    }
    \%param;
}

sub rect_center_1 {

    my $poly = Area::Polygon->new(%{create_rect_param;});

    my $center = $poly->center_by_points;

    my @expect = (1, 0.5);

    my $cmp_res;
    $cmp_res = 1;

    for (0 .. scalar(@$center) - 1) {
        $cmp_res = abs($expect[$_] - $center->[$_]) < 1e-5;
        last if !$cmp_res;
    } 
    ok($cmp_res, 'expect calculate first moment area for simple rectangle');
}

sub rect_center_1 {

    my $poly = Area::Polygon->new(%{create_rect_param;});

    my $center = $poly->center_by_points;

    my @expect = (1, 0.5);

    my $cmp_res;
    $cmp_res = 1;

    for (0 .. scalar(@$center) - 1) {
        $cmp_res = abs($expect[$_] - $center->[$_]) < 1e-5;
        last if !$cmp_res;
    } 
    ok($cmp_res, 'expect calculate is (1, 0.5) for simple rectangle');
}

sub create_param_sorted_keys
{
    my $params = shift;
    my @param_keys = sort {  
        $a =~ /p(.+)/;
        my $an = $1;
        $b =~ /p(.+)/; 
        my $bn = $1;
        $an <=> $bn;
    } keys %$params;

    \@param_keys;
}

sub symmetric_area_1 {
    my $params = create_symmetric_param_1;

    my $expected = 0;
    my @param_keys = @{create_param_sorted_keys $params;};


    for (0 .. $#param_keys) {
        my @points = (
            $params->{$param_keys[$_ - 1]},
            $params->{$param_keys[$_]} 
        );
        my $triangle = Area::Triangle->new(
            x1 => 0, y1 => 0,
            x2 => $points[0]->[0],
            y2 => $points[0]->[1],
            x3 => $points[1]->[0],
            y3 => $points[1]->[1]);
        $expected += $triangle->area;
    }
    my $poly = Area::Polygon->new(%{create_symmetric_param_2 1, 1;});
    
    my $area = $poly->area;

    my $cmp_res = abs($area - $expected) < 1e-5;

    ok($cmp_res, "expect area is $expected for symetric polygon");
}

sub symmetric_center_1 {

    my $params = create_symmetric_param_1;

    my $poly = Area::Polygon->new(%$params);

    my $center = $poly->center_by_points;

    my @expect = (0, 0);

    my $cmp_res;
    $cmp_res = 1;

    for (0 .. scalar(@$center) - 1) {
        $cmp_res = abs($expect[$_] - $center->[$_]) < 1e-2;
        last if !$cmp_res;
    } 
    ok($cmp_res, 'expect calculate center is (0, 0) for symetric polygon');
}

sub symmetric_center_2 {

    my $params = create_symmetric_param_2 1;

    my $poly = Area::Polygon->new(%$params);

    my $center = $poly->center_by_points;

    my @expect = (1, 0);

    my $cmp_res;
    $cmp_res = 1;

    for (0 .. scalar(@$center) - 1) {
        $cmp_res = abs($expect[$_] - $center->[$_]) < 1e-5;
        last if !$cmp_res;
    } 
    ok($cmp_res, 'expect calculate center is (1, 0) for symetric polygon');
}

sub symmetric_center_3 {

    my $params = create_symmetric_param_2 1, 1;

    my $poly = Area::Polygon->new(%$params);

    my $center = $poly->center_by_points;

    my @expect = (1, 1);

    my $cmp_res;
    $cmp_res = 1;

    for (0 .. scalar(@$center) - 1) {
        $cmp_res = abs($expect[$_] - $center->[$_]) < 1e-5;
        last if !$cmp_res;
    } 
    ok($cmp_res, 'expect calculate center is (1, 1) for symetric polygon');
}

sub symmetric_center_4 {

    my $params = create_symmetric_param_3;

    my $poly = Area::Polygon->new(%$params);

    my $center = $poly->center_by_points;

    my @expect = (0, 0);

    my $cmp_res;
    $cmp_res = 1;

    for (0 .. scalar(@$center) - 1) {
        $cmp_res = abs($expect[$_] - $center->[$_]) < 1e-5;
        last if !$cmp_res;
    } 
    ok($cmp_res, 'expect calculate center is (0, 0) for symetric polygon');
}

sub symmetric_center_5 {

    my $params = create_symmetric_param_3 1, 1;

    my $poly = Area::Polygon->new(%$params);

    my $center = $poly->center_by_points;

    my @expect = (1, 1);

    my $cmp_res;
    $cmp_res = 1;

    for (0 .. scalar(@$center) - 1) {
        $cmp_res = abs($expect[$_] - $center->[$_]) < 1e-5;
        last if !$cmp_res;
    } 
    ok($cmp_res, 'expect calculate center is (0, 0) for symetric polygon');
}



rect_center_1;
symmetric_area_1;
symmetric_center_1;
symmetric_center_2;
symmetric_center_3;
symmetric_center_4;
symmetric_center_5;

# vi: se ts=4 sw=4 et:
