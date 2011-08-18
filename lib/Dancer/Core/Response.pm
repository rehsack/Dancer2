package Dancer::Core::Response;

use strict;
use warnings;
use Carp;
use Moo;
use Dancer::Moo::Types;

use Scalar::Util qw/looks_like_number blessed/;
use Dancer::HTTP;
use Dancer::MIME;
use Dancer::Exception qw(:all);

with 'Dancer::Core::Role::Headers';

# boolean to tell if the route passes or not
has has_passed => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Bool(@_) },
    default => 0,
);

has encoded => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Bool(@_) },
    default => 0,
);

has halted => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Bool(@_) },
    default => 0,
);

has status => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Num(@_) },
    default => sub { 200 },
    coerce => sub {
        my ($status) = @_;
        return $status if looks_like_number($status);
        Dancer::HTTP->status($status);
    },
);

has content => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::Str(@_) },
    default => '',
);

sub to_psgi {
    my ($self) = @_;

    return [
        $self->status,
        $self->headers_to_array,
        [ $self->content ],
    ];
}

# sugar for accessing the content_type header, with mimetype care
sub content_type {
    my $self = shift;

    if (scalar @_ > 0) {
        my $mimetype = Dancer::MIME->instance();
        $self->header('Content-Type' => $mimetype->name_or_type(shift));
    } else {
        return $self->header('Content-Type');
    }
}

has _forward => (
    is => 'rw',
    isa => sub { Dancer::Moo::Types::HashRef(@_) },
);

sub forward {
    my ($self, $uri, $params, $opts) = @_;
    $self->_forward({to_url => $uri, params => $params, options => $opts});
}

sub is_forwarded {
    my $self = shift;
    $self->_forward;
}

# TODO should go elsewhere
#sub halt {
#    my ($self, $content) = @_;
#
#    if ( blessed($content) && $content->isa('Dancer::Response') ) {
#        $content->{halted} = 1;
#        Dancer::SharedData->response($content);
#    }
#    else {
#        # This also sets the Response as the current one (SharedData)
#        Dancer::Response->new(
#            status => ($self->status || 200),
#            content => $content,
#            halted => 1,
#        );
#    }
#    raise E_HALTED;
#}

1;
__END__
=head1 NAME

Dancer::Response - Response object for Dancer

=head1 SYNOPSIS

    # create a new response object
    Dancer::Response->new(
        status => 200,
        content => 'this is my content'
    );

    Dancer::SharedData->response->status; # 200

    # fetch current response object
    my $response = Dancer::SharedData->response;

    # fetch the current status
    $response->status; # 200

    # change the status
    $response->status(500);

=head1 PUBLIC API

=head2 new

    Dancer::Response->new(
        status  => 200,
        content => 'my content',
        headers => HTTP::Headers->new(...),
    );

create and return a new L<Dancer::Response> object

=head2 current

    my $response = Dancer::SharedData->response->current();

return the current Dancer::Response object, and reset the object

=head2 exists


    if ($response->exists) {
        ...
    }

test if the Dancer::Response object exists

=head2 content

    # get the content
    my $content = $response->content;
    my $content = Dancer::SharedData->response->content;

    # set the content
    $response->content('my new content');
    Dancer::SharedData->response->content('my new content');

set or get the content of the current response object

=head2 status

    # get the status
    my $status = $response->status;
    my $status = Dancer::SharedData->response->status;

    # set the status
    $response->status(201);
    Dancer::SharedData->response->status(201);

set or get the status of the current response object

=head2 content_type

    # get the status
    my $ct = $response->content_type;
    my $ct = Dancer::SharedData->response->content_type;

    # set the status
    $response->content_type('application/json');
    Dancer::SharedData->response->content_type('application/json');

set or get the status of the current response object

=head2 pass

    $response->pass;
    Dancer::SharedData->response->pass;

set the pass value to one for this response

=head2 has_passed

    if ($response->has_passed) {
        ...
    }

    if (Dancer::SharedData->response->has_passed) {
        ...
    }

test if the pass value is set to true

=head2 halt

    Dancer::SharedData->response->halt();
    $response->halt;

=head2 halted

    if (Dancer::SharedData->response->halted) {
       ...
    }

    if ($response->halted) {
        ...
    }

=head2 header

    # set the header
    $response->header('X-Foo' => 'bar');
    Dancer::SharedData->response->header('X-Foo' => 'bar');

    # get the header
    my $header = $response->header('X-Foo');
    my $header = Dancer::SharedData->response->header('X-Foo');

get or set the value of a header

=head2 headers

    $response->headers(HTTP::Headers->new(...));
    Dancer::SharedData->response->headers(HTTP::Headers->new(...));

return the list of headers for the current response

=head2 headers_to_array

    my $headers_psgi = $response->headers_to_array();
    my $headers_psgi = Dancer::SharedData->response->headers_to_array();

this method is called before returning a PSGI response. It transforms the list of headers to an array reference.


