use strict;

use Test::Simple tests => 20;
use Area::PathParser;

sub valid_parse_1
{
    my $lexer = Area::PathParser->lexer("M 90 10 h 5 5 5");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expect command 0 is \"M 90 10\"");
    ok($path->command_str(1) eq 'L 95 10',
        "expect command 1 is \"L 95 10\"");
    ok($path->command_str(2) eq 'L 100 10',
        "expect command 2 is \"L 100 10\"");
    ok($path->command_str(3) eq 'L 105 10',
        "exprect command 3 is \"L 105 10\"");
}

sub valid_parse_2
{
    my $lexer = Area::PathParser->lexer("M 90 10 H 5 10 15");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expected command 0 is \"M 90 10\"");
    ok($path->command_str(1) eq 'L 5 10',
        "expected command 1 is \"L 5 10\"");
    ok($path->command_str(2) eq 'L 10 10',
        "expected command 2 is \"L 10 10\"");
    ok($path->command_str(3) eq 'L 15 10',
        "exprected command 3 is \"L 15 10\"");
}

sub valid_parse_3
{
    my $lexer = Area::PathParser->lexer("M 90 10 v 5 5 5");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expect command 0 is \"M 90 10\"");
    ok($path->command_str(1) eq 'L 90 15',
        "expect command 1 is \"L 90 15\"");
    my $command_str = $path->command_str(2); 
    ok($path->command_str(2) eq 'L 90 20',
        "expect command 2 is \"L 90 20\". actual $command_str");
    ok($path->command_str(3) eq 'L 90 25',
        "exprect command 3 is \"L 90 25\"");
}

sub valid_parse_4
{
    my $lexer = Area::PathParser->lexer("M 90 10 V 5 10 15");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4, 'expected the path has 4 commands.');
    ok($path->command_str(0) eq 'M 90 10',
        "expected command 0 is \"M 90 10\"");
    ok($path->command_str(1) eq 'L 90 5',
        "expected command 1 is \"L 90 5\"");
    ok($path->command_str(2) eq 'L 90 10',
        "expected command 2 is \"L 90 10\"");
    ok($path->command_str(3) eq 'L 90 15',
        "exprected command 3 is \"L 90 15\"");
}


valid_parse_1;
valid_parse_2;
valid_parse_3;
valid_parse_4;

# vi: se ts=4 sw=4 et:
