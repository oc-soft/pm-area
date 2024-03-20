use strict;

use Test::Simple tests => 20;
use Area::PathParser;

sub valid_parse_1
{
    my $lexer = Area::PathParser->lexer(
        "M 90 10 c 3 4 5 6 10 20 "
        . "30 40 50 60 70 80 Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expect command 0 is \"M 90 10\"");
    my $command_str = $path->command_str(1);
    ok($path->command_str(1) eq 'C 93 14 95 16 100 30',
        "expect command 1 is \"C 93 14 95 16 100 30\". "
        . "Actual one is $command_str");
    ok($path->command_str(2) eq 'C 130 70 150 90 170 110',
        "expect command 2 is \"C 130 70 150 90 170 110\"");
    ok($path->command_str(3) eq 'Z',
        "exprect command 3 is \"Z\"");
}

sub valid_parse_2
{
    my $lexer = Area::PathParser->lexer(
        "M 90 10 C 5 10 15 20 20 30 "
        . "200 300 210 310 220 320 Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expected command 0 is \"M 90 10\"");
    ok($path->command_str(1) eq 'C 5 10 15 20 20 30',
        "expected command 1 is \"C 5 10 15 20 20 30\"");
    ok($path->command_str(2) eq 'C 200 300 210 310 220 320',
        "expected command 2 is \"C 200 300 210 310 220 320\"");
    ok($path->command_str(3) eq 'Z',
        "exprected command 3 is \"Z\"");
}

sub valid_parse_3
{
    my $lexer = Area::PathParser->lexer(
        "M 90 10 s 20 30 50 60 60 50 30 20Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expect command 0 is \"M 90 10\"");
    my $command_str = $path->command_str(1); 
    ok($path->command_str(1) eq 'C 90 10 110 40 140 70',
        "expect command 1 is "
        . "\"C 90 10 110 40 140 70\". acutual one is \"$command_str\"");
    $command_str = $path->command_str(2); 
    ok($path->command_str(2) eq 'C 170 100 200 120 170 90',
        "expect command 2 is "
        . "\"C 170 100 200 120 170 90\". actual one is \"$command_str\"");
    ok($path->command_str(3) eq 'Z',
        "exprect command 3 is \"Z\"");
}

sub valid_parse_4
{
    my $lexer = Area::PathParser->lexer("M 90 10 S 30 40 50 60 60 50 40 30 Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expected command 0 is \"M 90 10\"");
    ok($path->command_str(1) eq 'C 90 10 30 40 50 60',
        "expected command 1 is \"C 90 10 30 40 50 60\"");
    my $command_str = $path->command_str(2); 
    ok($path->command_str(2) eq 'C 70 80 60 50 40 30',
        "expected command 2 is "
        . "\"C 70 80 60 50 40 30\". actual one is \"$command_str\"");
    ok($path->command_str(3) eq 'Z',
        "exprected command 3 is \"Z\"");
}


valid_parse_1;
valid_parse_2;
valid_parse_3;
valid_parse_4;

# vi: se ts=4 sw=4 et:
