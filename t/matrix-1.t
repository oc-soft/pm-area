

use Test::Simple tests => 3;

use Area::Polygon::Matrix;


sub scale_t
{
    my $mat = Area::Polygon::Matrix->new(
        a => 2, d => 3);

    my $coord = $mat->apply(1, 1);    
    ok($coord->[0] == 2 && $coord->[1] == 3,
        'expected correct scale operation'); 
}

sub translate_t
{
    my $mat = Area::Polygon::Matrix->new(
        tx => 2, ty => -3);

    my $coord = $mat->apply(1, 1);    
    ok($coord->[0] == 3 && $coord->[1] == -2,
        "expected correct translate operation "
        . "(1, 1) => ($coord->[0], $coord->[1])"); 
}

sub skew_t
{
    my $mat = Area::Polygon::Matrix->new(
        b => 2, c => -3);

    my $coord = $mat->apply(1, 1);    
    ok($coord->[0] == -2 && $coord->[1] == 3,
        "expected correct skew operation "
        . "(1, 1) => ($coord->[0], $coord->[1])"); 
}


scale_t;
translate_t;
skew_t;

# vi: se ts=4 sw=4 et:
