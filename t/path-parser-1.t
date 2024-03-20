use strict;

use Test::Simple tests => 13;
use Area::PathParser;


sub valid_parse_1
{
    my $lexer = Area::PathParser->lexer("m 90 10");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 1, 'expected the path has one command.');
}

sub valid_parse_2
{
    my $lexer = Area::PathParser->lexer("m 1 1 23 40");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer);

    ok($path->command_count == 2,
        'expected the path has two commands.');
    ok($path->command_str(0) eq 'M 1 1',
        'expect first command is "M 1 1".');
    ok($path->command_str(1) eq 'L 24 41',
        'expect second cmmand is "L 24 41".');
}

sub valid_parse_3
{
    my $lexer = Area::PathParser->lexer("m 1 2 l 2 3 L 20 30");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 3,
        'expected the path has two commands.');
    ok($path->command_str(0) eq 'M 1 2',
        'expect first command is "M 1 2".');
    ok($path->command_str(1) eq 'L 3 5',
        'expect second cmmand is "L 3 5".');
    my $command_str = $path->command_str(2); 
    ok($path->command_str(2) eq 'L 20 30',
        "expect second cmmand is \"L 20 30\". but $command_str");
}

sub valid_parse_4
{
    my $lexer = Area::PathParser->lexer("   M 10 2 2 3 L 20 30 Z    ");

    my $parser = Area::PathParser->new;
        

    my $path = $parser->YYParse(yylex => $lexer,
        yydebug => 0x0);

    ok($path->command_count == 4,
        'expected the path has two commands.');
    ok($path->command_str(0) eq 'M 10 2',
        'expect first command is "M 20 2".');
    ok($path->command_str(1) eq 'L 2 3',
        'expect second cmmand is "L 2 3.');
    ok($path->command_str(2) eq 'L 20 30',
        'expect second cmmand is "L 20 30"');
    ok($path->command_str(3) eq 'Z',
        'expect second cmmand is "Z"');


}


valid_parse_1;
valid_parse_2;
valid_parse_3;
valid_parse_4;



# vi: se ts=4 sw=4 et:
