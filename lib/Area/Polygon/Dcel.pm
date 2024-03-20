use strict;
package Area::Polygon::Dcel;

use Dcel::Operation;

# find edge from vertex
sub find_edge_from_vertex {

    my ($face, $vertex) = @_;

    my $face_edge;
     
    Dcel::Operation->each_edge_around_origin($vertex->edge, sub {
        my $edge = shift;
        my $res = $edge->face == $face;
        $face_edge = $edge if $res;
        $res;
    });

    $face_edge;
}
1;
# vi: se ts=4 sw=4 et:
