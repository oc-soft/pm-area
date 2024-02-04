use strict;
use Test::Simple tests => 4;
use Area::Arc;

use Data::Dumper;

sub create_arc_param
{
    use Math::Trig;

    my ($start_deg, $end_deg, $rx, $ry, $cx, $cy) = @_;
    
    my ($start_rad, $end_rad) = (deg2rad($start_deg), deg2rad($end_deg)); 
     
    my @start_pt = ($rx * cos($start_rad) + $cx, $ry * sin($start_rad) + $cy);
    my @end_pt = ($rx * cos($end_rad) + $cx, $ry * sin($end_rad) + $cy);

    
    {
        x1 => $start_pt[0],
        y1 => $start_pt[1],
        x2 => $end_pt[0],
        y2 => $end_pt[1],
        rx => $rx,
        ry => $ry
    }
}



sub print_pi2
{
    use Math::Trig ':pi';
    print "pi: " . pi2 . "\n";
}

sub print_xy
{
    my $xy = shift;
    my ($x, $y) = ($xy->{x}, $xy->{y});
    print "x: $x\n";
    print "y: $y\n";
}

sub print_ceter_params
{
    use Math::Trig;
    my $params = shift;

    my ($cx, $cy, $theta, $dtheta, $rx, $ry) = (
        $params->{cx}, $params->{cy},
        $params->{theta}, $params->{dtheta},
        $params->{rx}, $params->{ry});
    my ($deg, $ddeg) = (rad2deg($theta), rad2deg($dtheta));

    print "cx: $cx\n";
    print "cy: $cy\n";
    print "theta: $theta($deg)\n";
    print "dtheat: $dtheta($ddeg)\n";
    print "rx: $rx\n";
    print "ry: $ry\n";
}

my $area1 = Area::Arc->new(
    rx => 10, ry => 10,
    x1 => 0, y1 => 10,
    x2 => 10, y2 => 0);

my $center_params = $area1->center_parameter();

ok(abs($center_params->{cx}) < 0.01 && abs($center_params->{cy}) < 0.01,
    sprintf('exptect center coordinate(%f, %f) is orgin',
        $center_params->{cx}, $center_params->{cy}));



my $param_2 = create_arc_param(0, 180, 20, 20, 0, 0);

my $area2 = Area::Arc->new(%$param_2);

$center_params = $area2->center_parameter();

ok(abs($center_params->{cx}) < 0.01 && abs($center_params->{cy}) < 0.01,
    sprintf('exptect center coordinate(%f, %f) is orgin',
        $center_params->{cx}, $center_params->{cy}));


my $param_3 = create_arc_param(0, 90, 20, 10, 30, 10);
$param_3->{sweep_flag} = 1;

my $area3 = Area::Arc->new(%$param_3);
$center_params = $area3->center_parameter();

ok(abs($center_params->{cx} - 30) < 0.01
    && abs($center_params->{cy} - 10) < 0.01,
    sprintf('exptect center coordinate(%f, %f) is (%f, %f)',
        $center_params->{cx}, $center_params->{cy}, 30, 10));



$param_3 = create_arc_param(30, 60, 20, 10, 30, 10);
$param_3->{sweep_flag} = 1;

$area3 = Area::Arc->new(%$param_3);
$center_params = $area3->center_parameter();

ok(abs($center_params->{cx} - 30) < 0.01
    && abs($center_params->{cy} - 10) < 0.01,
    sprintf('exptect center coordinate(%f, %f) is (%f, %f)',
        $center_params->{cx}, $center_params->{cy}, 30, 10));
# vi: se ts=4 sw=4 et:
