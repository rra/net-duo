#!/usr/bin/perl
#
# Test suite for the SMS sending functions.
#
# Written by Jon Robertson <jonrober@stanford.edu>
# Copyright 2014
#     The Board of Trustees of the Leland Stanford Junior University
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

use 5.014;
use strict;
use warnings;

use lib 't/lib';

use HTTP::Response;
use JSON;
use Test::Mock::Duo::Agent;
use Test::More;

BEGIN {
    use_ok('Net::Duo::Auth');
}

# Arguments for the Net::Duo constructor.
my %args = (key_file => 't/data/integrations/auth.json');

# Create the Net::Duo::Auth object with our testing integration configuration
# and a mock agent.
my $mock = Test::Mock::Duo::Agent->new(\%args);
$args{user_agent} = $mock;
my $duo = Net::Duo::Auth->new(\%args);
isa_ok($duo, 'Net::Duo::Auth');

# Create a JSON encoder.
my $json = JSON->new->utf8(1);

# Set expected data for a successful validation call.
my $reply = {
    stat     => 'OK',
    response => {
        result => 'deny',
        status => 'sent',
    },
};
my $response = HTTP::Response->new;
$response->code(200);
$response->message('Success');
$response->content($json->encode($reply));
$mock->expect(
    {
        method   => 'POST',
        uri      => '/auth/v2/auth',
        response => $response,
        content  => {
            username => 'user',
            factor   => 'sms',
            device   => 'auto',
        },
    }
);

# Make the call and check the response.
note('Testing token validation');
is($duo->sms_passcodes('user'), 'sent', 'Decoded /auth response is correct');

# Finished.  Tell Test::More that.
done_testing();
