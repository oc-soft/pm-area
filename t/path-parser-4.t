use strict;

use Test::Simple tests => 20;
use Area::PathParser;

sub valid_parse_1
{
    my $lexer = Area::PathParser->lexer(
        "M 90 10 q 3 4 10 20 "
        . "30 40 70 80 Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expect command 0 is \"M 90 10\"");
    my $command_str = $path->command_str(1);
    ok($path->command_str(1) eq 'Q 93 14 100 30',
        "expect command 1 is \"Q 93 14 100 30\". "
        . "Actual one is $command_str");
    ok($path->command_str(2) eq 'Q 130 70 170 110',
        "expect command 2 is \"Q 130 70 170 110\"");
    ok($path->command_str(3) eq 'Z',
        "exprect command 3 is \"Z\"");
}

sub valid_parse_2
{
    my $lexer = Area::PathParser->lexer(
        "M 90 10 Q 5 10 20 30 "
        . "200 300 220 320 Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expected command 0 is \"M 90 10\"");
    ok($path->command_str(1) eq 'Q 5 10 20 30',
        "expected command 1 is \"Q 5 10 20 30\"");
    ok($path->command_str(2) eq 'Q 200 300 220 320',
        "expected command 2 is \"Q 200 300 220 320\"");
    ok($path->command_str(3) eq 'Z',
        "exprected command 3 is \"Z\"");
}

sub valid_parse_3
{
    my $lexer = Area::PathParser->lexer(
        "M 90 10 t 50 60 30 20Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expect command 0 is \"M 90 10\"");
    my $command_str = $path->command_str(1); 
    ok($path->command_str(1) eq 'Q 90 10 140 70',
        "expect command 1 is "
        . "\"Q 90 10 140 70\". acutual one is \"$command_str\"");
    $command_str = $path->command_str(2); 
    ok($path->command_str(2) eq 'Q 190 130 170 90',
        "expect command 2 is "
        . "\"C 190 130 170 90\". actual one is \"$command_str\"");
    ok($path->command_str(3) eq 'Z',
        "exprect command 3 is \"Z\"");
}

sub valid_parse_4
{
    my $lexer = Area::PathParser->lexer("M 90 10 T 50 60 40 30 Z");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expected command 0 is \"M 90 10\"");
    my $command_str = $path->command_str(2); 
    ok($path->command_str(1) eq 'Q 90 10 50 60',
        "expected command 1 is "
        . "\"Q 90 10 50 60\". Actula one is \"$command_str\"");
    $command_str = $path->command_str(2); 
    ok($path->command_str(2) eq 'Q 10 110 40 30',
        "expected command 2 is "
        . "\"Q 10 110 40 30\". actual one is \"$command_str\"");
    ok($path->command_str(3) eq 'Z',
        "exprected command 3 is \"Z\"");
}


valid_parse_1;
valid_parse_2;
valid_parse_3;
valid_parse_4;

# vi: se ts=4 sw=4 et:
