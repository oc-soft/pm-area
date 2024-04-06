use strict;
use Math::Trig ':pi';

use Area::Polygon::Vertex;
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

    my @line_seg_params = (
        {
            v1 => Area::Polygon::Vertex->new(
                index => 0,
                point => [0, 1]
            ),
            v2 => Area::Polygon::Vertex->new(
                index => 1,
                point => [1, 2]
            ),
            direction => pip4,
        }, 
        {
            v1 => Area::Polygon::Vertex->new(
                index => 0,
                point => [1, 0]
            ),
            v2 => Area::Polygon::Vertex->new(
                index => 1,
                point => [1 + 2 * cos(pi / 3), 2 * sin(pi / 3)]
            ),
            direction => pi / 3
        },
        {
            v1 => Area::Polygon::Vertex->new(
                index => 0,
                point => [-5, 5]
            ),
            v2 => Area::Polygon::Vertex->new(
                index => 1,
                point => [-6, 5]
            ),
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
