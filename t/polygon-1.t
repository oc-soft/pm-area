
use strict;

use Test::Simple tests => 2;
use Area::Polygon;

use constant SVG_NS => 'http://www.w3.org/2000/svg';

sub load_path_from_svg
{
    use XML::LibXML;
    use Area::PathParser;
    my $svg_src = shift;

    my $dom = XML::LibXML->load_xml(location => $svg_src);

    my $doc_elem = $dom->documentElement;

    my $xpc = XML::LibXML::XPathContext->new;
    $xpc->registerNs('svg', SVG_NS);

    my @nodes = $xpc->findnodes('//svg:path[@d != ""]', $doc_elem);
    
    my $res;
    if (scalar @nodes) {
        my $path_d = $nodes[0]->getAttribute('d');
        my $parser = Area::PathParser->new;
        $res = $parser->YYParse(yylex => Area::PathParser->lexer($path_d));
    }
    $res;     
}


sub simple_polygon_1
{
    use File::Basename;
    use File::Spec;    
    my $test_file = File::Spec->catfile(
        dirname(__FILE__), 'polygon-test-1.svg'); 
    my $path = load_path_from_svg $test_file;

    my $polygons = $path->to_polygons;
    ok(scalar(@$polygons) == 1, 'load path correctly');


    my $triangles = $polygons->[0]->triangulation; 
    ok(scalar(@$triangles), 'expect the polygon has some triangles');
}

simple_polygon_1;

# vi: se ts=4 sw=4 et:
