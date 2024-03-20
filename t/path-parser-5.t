use strict;

use Test::Simple tests => 13;
use Area::PathParser;

sub valid_parse_1
{
    my $lexer = Area::PathParser->lexer(
        "M 90 10 a 3 4 10 1 0 10 20 "
        . "50 60 0 1 1 70 80 Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expect command 0 is \"M 90 10\"");
    my $command_str = $path->command_str(1);
    ok($path->command_str(1) eq 'A 3 4 10 1 0 100 30',
        "expect command 1 is \"A 3 4 10 1 0 100 30\". "
        . "Actual one is $command_str");
    ok($path->command_str(2) eq 'A 50 60 0 1 1 170 110',
        "expect command 2 is \"A 50 60 0 1 1 170 110\"");
    ok($path->command_str(3) eq 'Z',
        "exprect command 3 is \"Z\"");
}

sub valid_parse_2
{
    my $lexer = Area::PathParser->lexer(
        "M 90 10 A 12 14 10 1 1 20 30 "
        . "200 300 0 1 0 220 320 Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expected command 0 is \"M 90 10\"");
    ok($path->command_str(1) eq 'A 12 14 10 1 1 20 30',
        "expected command 1 is \"A 12 14 10 1 1 20 30\"");
    ok($path->command_str(2) eq 'A 200 300 0 1 0 220 320',
        "expected command 2 is \"A 200 300 0 1 0 220 320\"");
    ok($path->command_str(3) eq 'Z',
        "exprected command 3 is \"Z\"");
}

sub valid_parse_3
{
    my $lexer = Area::PathParser->lexer(
        "M 90 10 A 50, 60 10, 1, 1, 30 20");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 2, 'expected the path has 2 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expect command 0 is \"M 90 10\"");
    my $command_str = $path->command_str(1); 
    ok($path->command_str(1) eq 'A 50 60 10 1 1 30 20',
        "expect command 1 is "
        . "\"A 50 60 10 1 1 30 20\". acutual one is \"$command_str\"");
}


valid_parse_1;
valid_parse_2;
valid_parse_3;

# vi: se ts=4 sw=4 et:
