#!/usr/bin/perl
#
# Test suite for phone handling in the Admin API.
#
# Written by Russ Allbery <rra@cpan.org>
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

use JSON;
use Perl6::Slurp;
use Test::Mock::Duo::Agent;
use Test::More;
use Test::RRA::Duo qw(is_admin_phone);

BEGIN {
    use_ok('Net::Duo::Admin');
}

# Create a JSON decoder.
my $json = JSON->new->utf8(1);

# Arguments for the Net::Duo constructor.
my %args = (key_file => 't/data/integrations/admin.json');

# Create the Net::Duo::Auth object with our testing integration configuration
# and a mock agent.
my $mock = Test::Mock::Duo::Agent->new(\%args);
$args{user_agent} = $mock;
my $duo = Net::Duo::Admin->new(\%args);
isa_ok($duo, 'Net::Duo::Admin');

# Create a new phone.
my $data = {
    number => '+15555550100',
    name   => 'Random test phone',
};
$mock->expect(
    {
        method        => 'POST',
        uri           => '/admin/v1/phones',
        content       => $data,
        response_file => 't/data/responses/phone-create.json',
    }
);
note('Testing phone create endpoint');
my $phone = Net::Duo::Admin::Phone->create($duo, $data);

# Verify that the returned user is correct.  (Just use the same return data.)
my $raw      = slurp('t/data/responses/phone-create.json');
my $expected = $json->decode($raw);
is_admin_phone($phone, $expected);

# Finished.  Tell Test::More that.
done_testing();
