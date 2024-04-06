
use strict;

use Test::Simple tests => 5; 
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

sub compare_number_arrays {
    my ($array_0, $array_1) = @_;
    
    my $len_0 = scalar @$array_0;
    my $len_1 = scalar @$array_1;
    my $comp_len = $len_0 < $len_1 ? $len_0 : $len_1;
    my $res = 0;
    for (0 .. $comp_len - 1) {
        $res = $array_0->[$_] <=> $array_1->[$_];
        last if $res;
    }
    if ($res == 0) {
        $res = $len_0 <=> $len_1;
    }
    $res;
}

sub compare_number_arrays_arrays {
    my ($num_arrays_0, $num_arrays_1) = @_;
    my $len_0 = scalar @$num_arrays_0;
    my $len_1 = scalar @$num_arrays_1;
    my $comp_len = $len_0 < $len_1 ? $len_0 : $len_1;
    my $res = 0;
    for (0 .. $comp_len - 1) {
        $res = compare_number_arrays $num_arrays_0->[$_], $num_arrays_1->[$_];
        last if $res;
    }
    if ($res == 0) {
        $res = $len_0 <=> $len_1;
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
    my $test_res = scalar(@$polygons) == 1;
    ok($test_res, 'load path correctly');

    $polygons->[0]->freeze;
    my $indices = $polygons->[0]->monotone_indices; 
    my @expects = (
        [ 0, 1, 2, 3, 7, 8 ],
        [ 3, 4, 5 ],
        [ 3, 5, 6, 7 ]
    );

    my $cmp_res = compare_number_arrays_arrays $indices, \@expects; 
    $test_res = $cmp_res == 0;
    ok($test_res, 'expect success to run monotone_indices');
}

sub simple_polygon_2
{
    use File::Basename;
    use File::Spec;    
    my $test_file = File::Spec->catfile(
        dirname(__FILE__), 'polygon-test-1.svg'); 
    my $path = load_path_from_svg $test_file;

    my $polygons = $path->to_polygons;
    my $test_res;

    $polygons->[0]->freeze;
    my $indices = $polygons->[0]->monotone_mountain_indices; 
    my @expects = (
        [ 0, 1, 7, 8 ],
        [ 1, 2, 3, 7 ],
        [ 3, 4, 5 ],
        [ 3, 5, 6, 7 ]
    );
    my $cmp_res = compare_number_arrays_arrays $indices, \@expects; 
    $test_res = $cmp_res == 0;
    ok($test_res, 'expect success to run monotone_mountain_indices');
}

sub simple_polygon_3
{
    use File::Basename;
    use File::Spec;    
    my $test_file = File::Spec->catfile(
        dirname(__FILE__), 'polygon-test-2.svg'); 
    my $path = load_path_from_svg $test_file;

    my $polygons = $path->to_polygons;
    my $test_res;

    $polygons->[0]->freeze;
    my $indices = $polygons->[0]->monotone_indices; 
    my @expects = (
        [ 0, 1, 13 ],
        [ 1, 2, 3, 4, 6, 8, 9 ],
        [ 1, 9, 10, 11, 13 ],
        [ 4, 5, 6 ],
        [ 6, 7, 8 ],
        [ 11, 12, 13 ]
    );
    my $cmp_res = compare_number_arrays_arrays $indices, \@expects; 
    $test_res = $cmp_res == 0;
    ok($test_res, 'expect success to run monotone_indices');
}

sub simple_polygon_4
{
    use File::Basename;
    use File::Spec;    
    my $test_file = File::Spec->catfile(
        dirname(__FILE__), 'polygon-test-2.svg'); 
    my $path = load_path_from_svg $test_file;

    my $polygons = $path->to_polygons;
    my $test_res;

    $polygons->[0]->freeze;
    my $indices = $polygons->[0]->monotone_mountain_indices; 
    my @expects = (
        [ 0, 1, 13 ],
        [ 1, 2, 3, 9 ],
        [ 1, 9, 10, 11, 13 ],
        [ 3, 4, 6, 8 ],
        [ 3, 8, 9 ],
        [ 4, 5, 6 ],
        [ 6, 7, 8 ],
        [ 11, 12, 13 ]
    );
    my $cmp_res = compare_number_arrays_arrays $indices, \@expects; 
    $test_res = $cmp_res == 0;
    ok($test_res, 'expect success to run monotone_mountain_indices');
}


simple_polygon_1;
simple_polygon_2;
simple_polygon_3;
simple_polygon_4;

# vi: se ts=4 sw=4 et:
