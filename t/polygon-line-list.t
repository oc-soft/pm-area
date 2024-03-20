use strict;

use Area::Polygon::LineSegment;
use Area::Polygon::LineSegmentList;

use Test::Simple tests => 3;

sub find_direction
{
    my ($directions, $direction) = @_;

    my $res = 0;
    for (@$directions) {
        $res = abs($_) - abs($direction) < 0.000001;
        last if $res;
    }
    $res;
}

sub directions_test
{
    use Math::Trig ':pi';
    my @line_seg_params = (
        {
            p1 => [0, 1],
            p2 => [1, 2],
            direction => pip4,
        }, 
        {
            p1 => [1, 0],
            p2 => [1 + 2 * cos(pi / 3), 2 * sin(pi / 3)],
            direction => pi / 3
        },
        {
            p1 => [-5, 5],
            p2 => [-6, 5],
            direction => pi 
        }
    );
    my $line_seg_list = Area::Polygon::LineSegmentList->new;

    my $succeeded = 0;
    my @directions;
    for (@line_seg_params) {
        my $line_seg = Area::Polygon::LineSegment->new(%$_);
        $succeeded = $line_seg ? 1 : 0;
        last if !$succeeded;
        $line_seg_list->add_line($line_seg);
        push @directions, $_->{direction};
    }
     
    ok($succeeded, 'expected all line segments created'); 
    $succeeded = $line_seg_list->count == scalar(@line_seg_params);
    ok($succeeded, 'expected line segment lists has all line segment');
   
    for (@{$line_seg_list->all_directions_as_radian}) {
        $succeeded = find_direction \@directions, $_; 
    } 
    ok($succeeded, 'expected all diretions are calculated correctly');
}

directions_test;

# vi: se ts=4 sw=4 et:
