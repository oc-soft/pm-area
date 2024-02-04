package Area::Arc;
use Moose;

has ['rx', 'ry'] => (
    is => 'ro',
    isa => 'Num',
    required => 1,
);


has ['x1', 'y1', 'x2', 'y2'] => (
    is => 'ro',
    isa => 'Num',
    required => 1,
);

has angle => (
    is => 'ro',
    isa => 'Num',
    required => 0,
    default => 0
);
has ['large_arc_flag', 'sweep_flag'] => (
    is =>  'ro',
    isa => 'Bool',
    required => 0,
    default => 0
);


# calculate center coordinate
sub center
{
     
    my $area = area(@_);
    my $res;
    if ($area > 0) {
        my $fmoa = first_moment_of_area(@_);
        $res = { 
            x => $fmoa->{cx} / $area,
            y => $fmoa->{cy} / $area
        };
    } else {
        my $self = $_[0];
        if ($self->{rx} && $self->{ry}) {
            my $center_param = $self->center_parameter();
            $res = { 
                x => ($self->{x1} + $self->{x2} + $center_param->{cx}) / 3,
                y => ($self->{y1} + $self->{y2} + $center_param->{cy}) / 2
            };
        } else {
            $res = { 
                x => ($self->{x1} + $self->{x2}) / 2,
                y => ($self->{y1} + $self->{y2}) / 2
            };
        }
    }
    $res;
}

# calculate area
sub area
{
    my ($self, $theta_step, $mode) = @_;

    my $res = 0;
    if ($mode == 'large') {
       $res = $self->_area($theta_step, 1); 
    } elsif ($mode == 'small') {
       $res = $self->_area($theta_step, 1); 
    } else {
        my @area_array = (
            $self->area($theta_step, 'large'),
            $self->area($theta_step, 'small')
        );
        for (@area_array) {
            $res += $_;
        }
        $res /= scalar(@area_array);
    }
    return $res;
}


sub _area
{
    my $triangles = triangles(@_);
    
    my $res = 0;
    for (@$triangles) {
        $res += $_->area();
    }
    $res;
}

# calcurate first moment of area
sub first_moment_of_area
{
    my ($self, $theta_step, $mode) = @_;

    my $res;
    if ($mode == 'large') {
        $res = _first_moment_of_area($self, $theta_step, 1);
    } elsif ($mode == 'small') {
        $res = _first_moment_of_area($self, $theta_step, 0);
    } else {
        my @fmoa = (
            first_moment_of_area($self, $theta_step, 1),
            first_moment_of_area($self, $theta_step, 0)
        );
        my %fmoa;
        $fmoa{sx} = ($fmoa[0]->{sx} + $fmoa[1]->{sx}) / 2;
        $fmoa{sy} = ($fmoa[0]->{sy} + $fmoa[1]->{sy}) / 2;
        $res = \%fmoa;
    }
    $res; 
}

sub _first_moment_of_area
{
    my ($self, $theta_step, $external) = @_;

    my $triangles = triangulation($self, $theta_step, $external);

    my %fmoa = (sx => 0, sy => 0);
    for (@$triangles) {

        my $center = $_->center();
        my $area = $_->area();

        $fmoa{sx} += $area * $center->{x};
        $fmoa{sy} += $area * $center->{y};
    }
    \%fmoa; 
}

# calculate paremeter for elipse wth center, angle and displacement of angle.
sub center_parameter
{
    my $self = shift;

    my $xdyd = $self->_compute_xdyd();
    my $radii = $self->_compute_radii($xdyd->{x}, $xdyd->{y});
    my $cxdcyd = $self->_compute_cxdcyd($xdyd->{x}, $xdyd->{y}, 
        $radii->{rx}, $radii->{ry});
    my $cxcy = $self->_compute_cxcy($cxdcyd->{x}, $cxdcyd->{y});
    my $theta = $self->_compute_theta(
        $xdyd->{x}, $xdyd->{y}, $cxdcyd->{x}, $cxdcyd->{y}, 
            $radii->{rx}, $radii->{ry});
    my $dtheta = $self->_compute_deleta_theta(
        $xdyd->{x}, $xdyd->{y}, $cxdcyd->{x}, $cxdcyd->{y}, 
            $radii->{rx}, $radii->{ry});
     
    {
        cx => $cxcy->{x},
        cy => $cxcy->{y},
        theta => $theta,
        dtheta => $dtheta,
        rx => $radii->{rx},
        ry => $radii->{ry} 
    };
}

# create triangles polygon 
sub triangulation
{
    use Math::Trig ':pi';
    my ($self, $theta_step, $external) = @_; 

    $theta_step = pi / 12 if !$theta_step; 
    
    my $center_params = center_parameter($self);
    my @triangles;
    if ($center_params->{dtheta}) { 
        my $sign = $center_params->{dtheta} >= 1 ? 1 : -1;

        $theta_step = abs($theta_step); 
        
        my $abs_dtheta = abs($center_params->{dtheta});
        my $step_count = int($abs_dtheta / $theta_step);

        my $edge_step = ($abs_dtheta - $step_count * $theta_step) / 2;


        my $current_theta = $center_params->{theta};
        if ($edge_step) {
            push(@triangles, _create_triangle(
                $center_params->{rx}, $center_params->{ry}, 
                $current_theta, $sign * $edge_step,
                $center_params->{cx}, $center_params->{cy}, $external)); 
            $current_theta = $center_params->{theta} + $sign * $edge_step;
        }

        for (0 .. $step_count - 1) {
            push(@triangles, _create_triangle(
                $center_params->{rx}, $center_params->{ry}, 
                $current_theta, $sign * $theta_step,
                $center_params->{cx}, $center_params->{cy}, $external)); 
            $current_theta += $sign * $theta_step; 
        }
        if ($edge_step) {
            push(@triangles, _create_triangle(
                $center_params->{rx}, $center_params->{ry}, 
                $current_theta, $sign * $edge_step,
                $center_params->{cx}, $center_params->{cy}, $external)); 
        }
    }
    \@triangles;
}

# create a triangle
sub _create_triangle
{
    use Area::Triangle;
    my ($rx, $ry, $theta, $dtheta, $cx, $cy, $external) = @_;

    my $scale = 1;
    if ($external) {
        use Math::Trig;
        $scale = sec(abs($dtheta) / 2);
    }


    my %triangle_param;

    $triangle_param{x1} = $cx;
    $triangle_param{y1} = $cy;

    $triangle_param{x2} = $scale * $rx * cos($theta) + $cx;
    $triangle_param{y2} = $scale * $ry * sin($theta) + $cy;

    $triangle_param{x3} = $scale * $rx * cos($theta + $dtheta) + $cx;
    $triangle_param{y3} = $scale * $ry * sin($theta + $dtheta) + $cy;

    Area::Triangle->new(\%triangle_param);
}


# compute radii
sub _compute_radii
{
    my ($self, $xd, $yd) = @_;

    my $lambda = $xd ** 2 / $self->rx ** 2;
    $lambda += $yd ** 2 / $self->ry ** 2;

    my $res = {
        rx => $self->rx,
        ry => $self->ry
    };
    if ($lambda > 1)
    {
        my $lambda_sqrt = sqrt($lambda);
        $res->{rx} = $lambda_sqrt * $self->rx;
        $res->{ry} = $lambda_sqrt * $self->ry;
    } 
    $res;
}

# compute x' and y'
sub _compute_xdyd
{
    use Math::Trig;
    my $self = shift;
    my $phai = deg2rad($self->angle);
    my ($cos_phai, $sin_phai) = (cos($phai), sin($phai));

    my ($xd2, $yd2) = (
        ($self->x1 - $self->x2) / 2,
        ($self->y1 - $self->y2) / 2
    );

    { 
        x => $cos_phai * $xd2 + $sin_phai * $yd2,
        y => -$sin_phai * $xd2 + $cos_phai * $yd2
    };
}

sub _compute_cxdcyd
{
    my ($self, $xd, $yd, $rx, $ry) = @_;

    my $rxry2 = $rx ** 2 * $ry ** 2;
    my $rxyd = $rx ** 2 * $yd ** 2;
    my $ryxd = $ry ** 2 * $xd ** 2;

    my $a = sqrt(($rxry2 - $rxyd - $ryxd) / ($rxyd + $ryxd));
    my $sign = $self->large_arc_flag != $self->sweep_flag ? 1 : -1;

    my $rxyry = $rx * $yd / $ry;
    my $ryxrx = - ($ry * $xd) / $rx;
    
    { 
        x => $sign * $a * $rxyry,
        y => $sign * $a * $ryxrx
    };
}
sub _compute_cxcy
{
    use Math::Trig;
    my ($self, $cxd, $cyd) = @_;
    my $phai = deg2rad($self->angle);
    my ($cos_phai, $sin_phai) = (cos($phai), sin($phai));

    { 
        x => $cos_phai * $cxd - $sin_phai * $cyd
            + ($self->x1 + $self->x2) / 2,
        y => $sin_phai * $cxd + $cos_phai * $cyd
            + ($self->y1 + $self->y2) / 2
    }; 
}

sub _compute_theta
{
    my ($self, $xd, $yd, $cxd, $cyd, $rx, $ry) = @_;

    my @u = (1, 0);
    my @v = (($xd - $cxd) / $rx,  ($yd - $cyd) / $ry);

    _compute_theta_uv(\@u, \@v);
}

sub _compute_deleta_theta
{
    use Math::Trig ':pi';
    my ($self, $xd, $yd, $cxd, $cyd, $rx, $ry) = @_;

    my @u = (($xd - $cxd) / $rx, ($yd - $cyd) / $ry);
    my @v = ((-$xd - $cxd) / $rx,  (-$yd - $cyd) / $ry);

    my $delta_theta = _compute_theta_uv(\@u, \@v);

    if (!$self->sweep_flag && $delta_theta > 0)
    {
        $delta_theta -= pi2;
    }
    elsif ($self->sweep_flag && $delta_theta < 0)
    {
        $delta_theta += pi2;
    }
    $delta_theta;
}


sub _compute_theta_uv
{
    use Math::Trig;
    my ($u, $v) = @_;

    my $uvi = $u->[0] * $v->[0] + $u->[1] * $v->[1]; 

    my $sign = $u->[0] * $v->[1] - $u->[1] * $v->[0];
    if ($sign >= 0)
    {
        $sign = 1; 
    }
    else
    {
        $sign = -1; 
    }
    my $ul = sqrt($u->[0] ** 2 + $u->[1] ** 2);
    my $vl = sqrt($v->[0] ** 2 + $v->[1] ** 2); 

    $sign * acos($uvi / ($ul * $vl));
}

1;

__END__

=pod

=head1 NAME

Area::Arc - area geometric function utility

Arc parameters are identical A command in svg path's d attributes. see L<svg reference arc implementation|https://svgwg.org/svg2-draft/implnote.html#ArcImplementationNotes>

=head1 SYNOPSIS

 use Area::Arc;

 # create new instance of ellipse from (x1, y1) to (x2, y2) 
 $arc = Area::Arc->new(rx => 10, ry => 10,
     x1 => 0, y1 => 10,
     x2 => 10, y2 => 0);


=head1 OBJECT-ORIENTED INTERFACE

=head2 new

create (x1, y1) to (x2, y2) arc

 $arc = Area::Arc->new(rx => 10, ry => 10,
     x1 => 0, y1 => 10,
     x2 => 10, y2 => 0,
     large_arc_flag => 0,
     sweep_flag => 0);

=head2 center

You get center coordinate

=over

=item 1st parameter

You specify displacment each angle (rad) from (x1, y1) to (x2, y2)

=item 2nd parameter

You specify triangle type. 

=over

=item 'large'

You get area with triangles over the arc.

=item 'small' 

You get area with triangles in the arc. 

=item else

You get result average between 'large' and 'small'.

=back

=back

=item return

HASH reference x and y coordinate

You get hash reference 

 # calculate center coordinate
 $center_coord = $arc->center();

 print 'x:' . $center_coord->{x} . "\n";
 print 'y:' . $center_coord->{y} . "\n";
  

=head2 area

You get area of arc.

=over

=item 1st parameter

You specify displacment each angle (rad) from (x1, y1) to (x2, y2)

=item 2nd parameter

You specify triangle type. 

=over

=item 'large'

You get area with triangles over the arc.

=item 'small' 

You get area with triangles in the arc. 

=item else

You get result average between 'large' and 'small'.

=back

=back

 # you get area with triangles over the arc
 $area = $arc->area(
     pi2 / 12, # theta displacment steps from (x1, y1) to (x2, y2)
     'large');

=head2 first_moment_of_area

You get first moment area data.

=over

=item 1st parameter

You specify displacment angle (rad) from (x1, y1) to (x2, y2)

=item 2nd parameter

You specify triangle type. 

=over

=item 'large'

You get result with triangles over the arc area.

=item 'small' 

You get result with triangles in the arc  area. 

=item else

You get result average between 'large' and 'small'.

=back

=back

 use Math::Trig ':pi';
 my $fma = $area->first_moment_of_area(
     pi2 / 12, # theta stride from (x1, y1) to (x2, y2)
     'large' # tranguration type
     );

=head2 triangulation

You get array reference of L<Area::Triangle> of arc.

=over

=item 1st parameter

You specify displacment angle (rad) stride each from (x1, y1) to (x2, y2)

=item 2nd parameter

You specify true value if you want to get triangles which is over the arc. 


=item return

You get array reference of L<Area::Triangle> of arc.

=back

 use Math::Trig ':pi';
 my $triangles = $arc->triangulation(
     pi / 6,
     1);
     
 for (@$triangles) {
     print 'area: ' . $_->area() . "\n";
 }


=head2 center_parameter

calculate paremeter for ellipse wth center, angle and displacement of angle.


=over

=item return

You get HASH reference of paremter for ellipse.

=over

=item cx

x coordinate of ellipse's center

=item cy

y coordinate of ellipse's center


=item theta

start angle (rad) of ellipse

=item dtheta

displacement angle from start angle to end angle of ellipse's center.


=item rx

x directional radius.

=item ry

y directional radius.

=back

 my $params = $arc->center_paramenter;
     
 print 'cx:     ' . $params->{cx} . "\n";
 print 'cy:     ' . $params->{cy} . "\n";
 print 'theta:  ' . $params->{theta} . "\n";
 print 'dtheta: ' . $params->{dtheta} . "\n";
 print 'rx:     ' . $params->{rx} . "\n";
 print 'ry:     ' . $params->{ry} . "\n";


=cut

# vi: se ts=4 sw=4 et:
