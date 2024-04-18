package Area::Polygon::Error;

use strict;
use Area::L10n;

# create instance
sub new {
    my ($class, %args) = @_;

    my $res = bless {}, $class; 

    $res->error_str(%args);
    $res->message_parameter(%args);
    $res->data(%args);
    $res->code(%args);
    $res;
}

# parameter
sub message {
    my $self = shift;

    my $lh = Area::L10n->get_handle;
    my $msg_params = $self->message_parameter;
    my $res;
    if (defined $msg_params) {
        $res = $lh->maketext($self->error_str, @$msg_params);
    } else {
        $res = $lh->maketext($self->error_str);
    }
    $res;
}

# error specific data
sub data {
    my ($self, %args) = @_;
    my $res = $self->{data};
    if (defined $args{data}) {
        $self->{data} = $args{data};
    }
    $res;
}

# internal error string
sub error_str {
    my ($self, %args) = @_;
    my $res = $self->{error_str};
    if (defined $args{error_str}) {
        $self->{error_str} = $args{error_str};
    }
    $res;
}

# message parameter
sub message_parameter {
    my ($self, %args) = @_;
    my $res = $self->{message_parameter};
    if (defined $args{message_parameter}) {
        $self->{message_parameter} = $args{message_parameter};
    }
    $res;
}

# error code
sub code {
    my ($self, %args) = @_;
    my $res = $self->{code};
    if (defined $args{code}) {
        $self->{code} = $args{code};
    }
    $res;
}

1;
# vi: se ts=4 sw=4 et:
