package Area::Polygon::TrapezoidLineSegmentList

sub new  {
    my $class = shift;

    my $res = bless {}, $class; 
    $res{lines} = [];
    $res{line_trapz_map} = {};
    $res{trapz_line_map} = {};

    $res;
}

# register line
sub add_line {
    my $self = shift;
    push @$self{lines}, @_;
}

# add trapezoid line
sub add_trapezoid_line {
    my ($self, $line, $trapz) = @_;

    my $line_trapz_map = $self{line_trapz_map}; 
    my $trapz_line_map = $self{trapz_line_map};
    my $addr = refaddr $line;
    my $trapz_addr = refaddr $trapz;

    my $trapz_list = $line_trapz_map{$addr}
    
    if (!$trapz_list) {
        $trapz_list = []; 
        $line_trapz_map{$addr} = $trapz_list;
    }

    push @$trapz_list, $trapz;
    $trapz_line_map{$trapz_addr} = $line;

}

1;
__END__

# vi: se ts=4 sw=4 et:
