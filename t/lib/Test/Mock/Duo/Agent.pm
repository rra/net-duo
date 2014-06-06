# Mock LWP::UserAgent for Duo testing.
#
# This module provides the same interface as LWP::UserAgent, for the methods
# that Net::Duo calls, and verifies that the information passed in by Duo is
# correct.  It can also simulate responses to exercise response handling in
# Net::Duo.
#
# All tests are reported by Test::More, and no effort is made to produce a
# predictable number of test results.  This means that any calling test
# program should probably not specify a plan and instead use done_testing().

package Test::Mock::Duo::Agent 1.00;

use 5.014;
use strict;
use warnings;

use Carp qw(croak);
use Encode qw(decode);
use HTTP::Request;
use HTTP::Response;
use JSON;
use Perl6::Slurp qw(slurp);
use Test::More;
use URI::Escape qw(uri_unescape);

##############################################################################
# Mock API
##############################################################################

# Stubbed out for now.
sub _verify_signature {
    my ($self, $request) = @_;
    return;
}

# Given an HTTP::Request, pretend to perform the request and return an
# HTTP::Response object.  The content of the HTTP::Response object will be
# determined by the most recent calls to the testing API.  Each request resets
# the response.  If no response has been configured, throw an exception.
#
# $self    - Test::Mock::Duo::Agent object
# $request - HTTP::Request object to verify
#
# Returns: An HTTP::Response object
#  Throws: Exception on fatally bad requests or on an unconfigured test
sub request {
    my ($self, $request) = @_;

    # Throw an exception if we got an unexpected call.
    if (!$self->{expected}) {
        croak('saw an unexpected request');
    }

    # Verify the signature on the request.  We continue even if it doesn't
    # verify and check the rest of the results.
    $self->_verify_signature($request);

    # Ensure the method and URI match what we expect, and extract the content.
    is($request->method, $self->{expected}{method}, 'Method');
    my $uri = $request->uri;
    my $content;
    if ($request->method eq 'GET') {
        if ($uri =~ s{ [?] (.*) }{}xms) {
            $content = $1;
        } else {
            $content = q{};
        }
    } else {
        $content = $request->content;
    }
    is($uri, $self->{expected}{uri}, 'URI');

    # Decode the content.
    my @pairs = split(m{&}xms, $content // q{});
    my %content;
    for my $pair (@pairs) {
        my ($key, $value) = split(m{=}xms, $pair, 2);
        $key   = decode('UTF-8', uri_unescape($key));
        $value = decode('UTF-8', uri_unescape($value));
        $content{$key} = $value;
    }

    # Check the content.
    if ($self->{expected}{content}) {
        is_deeply(\%content, $self->{expected}{content}, 'Content');
    } else {
        is($content, q{}, 'Content');
    }

    # Return the configured response and clear state.
    my $response = $self->{expected}{response};
    delete $self->{expected};
    return $response;
}

##############################################################################
# Test API
##############################################################################

# Constructor for the mock agent.  Takes the same arguments as are passed to
# the Net::Duo constructor (minus the user_agent argument) so that the mock
# knows the expected keys and hostname.
#
# $class    - Class into which to bless the object
# $args_ref - Arguments to the Net::Duo constructor
#   api_hostname    - API hostname for the Duo API integration
#   integration_key - Public key for the Duo API integration
#   key_file        - Path to file with integration information
#   secret_key      - Secret key for the Duo API integration
#
# Returns: New Test::Mock::Duo::Agent object
#  Throws: Text exception on failure to read keys
sub new {
    my ($class, $args_ref) = @_;
    my $self = {};

    # Load integration information from key_file if set.
    my $keys;
    if ($args_ref->{key_file}) {
        my $json     = JSON->new()->relaxed(1);
        my $key_data = slurp($args_ref->{key_file});
        $keys = $json->decode($key_data);
    }

    # Integration data from $args_ref overrides key_file data.
    for my $key (qw(api_hostname integration_key secret_key)) {
        $self->{$key} = $args_ref->{$key} // $keys->{$key};
    }

    # Create the JSON decoder that we'll use for subsequent operations.
    $self->{json} = JSON->new->utf8(1);

    # Bless and return the new object.
    bless($self, $class);
    return $self;
}

# Configure an expected request and the response to return.  Either response
# or response_file should be given.  If response_file is given, an
# HTTP::Response with a status code of 200 and the contents of that file as
# the body (Content-Type: application/json).
#
# $self     - Test::Mock::Duo::Agent object
# $args_ref - Expected request and response information
#   method        - Expected method of the request
#   uri           - Expected URI of the request without any query string
#   content       - Expected query or post data as reference (may be undef)
#   response      - HTTP::Response object to return to the caller
#   response_data - Partial data structure to add to generic JSON in response
#   response_file - File containing JSON to return as a respose
#
# Returns: undef
#  Throws: Text exception on invalid parameters
#          Text exception if response_file is not readable
sub expect {
    my ($self, $args_ref) = @_;

    # Verify consistency of the arguments.
    my @response_args = qw(response response_data response_file);
    my $response_count = grep { defined($args_ref->{$_}) } @response_args;
    if ($response_count < 1) {
        croak('no response, response_data, or response_file specified');
    } elsif ($response_count > 1) {
        croak('too many of response, response_data, and response_file given');
    }

    # Build the response object if needed.
    my $response;
    if ($args_ref->{response}) {
        $response = $args_ref->{response};
    } else {
        $response = HTTP::Response->new(200, 'Success');
        $response->header('Content-Type', 'application/json');
        my $reply;
        if (defined($args_ref->{response_data})) {
            my $data = $args_ref->{response_data};
            $reply = { stat => 'OK', response => $data };
        } else {
            my $contents = slurp($args_ref->{response_file});
            my $data     = $self->{json}->decode($contents);
            $reply = { stat => 'OK', response => $data };
        }
        $response->content($self->{json}->encode($reply));
    }

    # Set the expected information for call verification later.
    $self->{expected} = {
        method   => $args_ref->{method},
        uri      => 'https://' . $self->{api_hostname} . $args_ref->{uri},
        content  => $args_ref->{content},
        response => $response,
    };
    return;
}

1;
__END__
