use strict;
use Test::Simple tests => 6;
use Area::Path;

sub add_moveto
{
    my $path = shift;

    $path->moveto(10, 2);
    my $str = $path->command_str($path->command_count - 1);

    ok($str == 'M 10 2', 'expected added moveto');
}

sub add_lineto
{
    my $path = shift;

    $path->lineto(15, 20);
    my $str = $path->command_str($path->command_count - 1);

    ok($str == 'L 15 20', 'expected added lineto');
}

sub add_cubic_bezierto
{
    my $path = shift;

    $path->cubic_bezierto(110, 203, 21, 45, 37, 58);
    my $str = $path->command_str($path->command_count - 1);

    ok($str == 'C 110 203 21 45 37 58', 'expected added cubic_bezierto');
}

sub add_quadratic_bezierto
{
    my $path = shift;

    $path->cubic_bezierto(6, 2, 9, 5);
    my $str = $path->command_str($path->command_count - 1);

    ok($str == 'Q 6 2 9 5', 'expected added quadratic_bezierto');
}

sub add_arcto
{
    my $path = shift;

    $path->arcto(10, 12, 13, 1, 0, 234, 678);
    my $str = $path->command_str($path->command_count - 1);

    ok($str == 'A 10 12 13 1 0 234 678', 'expected added arcto');
}

sub add_close:
{
    my $path = shift;

    $path->close;
    my $str = $path->command_str($path->command_count - 1);

    ok($str == 'Z', 'expected added close');
}


my $path = Area::Path->new;

add_moveto $path;
add_lineto $path;
add_cubic_bezierto $path;
add_quadratic_bezierto $path;
add_arcto $path;
add_close $path;

# vi: se ts=4 sw=4 et:
