#!/usr/bin/perl
#
# Test suite for user handling in the Admin API.
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

# Try a users call, returning the test user data.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/users',
        response_file => 't/data/responses/users.json',
    }
);
note('Testing users endpoint with no search');
my @users = $duo->users;

# Should be an array of a single user.
is(scalar(@users), 1, 'users method returns a single user');
my $user = $users[0];
isa_ok($user, 'Net::Duo::Admin::User');

# Check the top-level, simple data.  We can't just use is_deeply on the
# top-level object because we've converted some of the underlying hashes to
# other objects, so we walk specific keys and confirm they match.
my $raw      = slurp('t/data/responses/users.json');
my $expected = $json->decode($raw)->[0];
for my $key (qw(user_id username realname email status last_login notes)) {
    is($user->$key, $expected->{$key}, "...$key");
}

# Should be one group.
my @groups = $user->groups;
is(scalar(@groups), 1, '...one group');
my $group = $groups[0];
isa_ok($group, 'Net::Duo::Admin::Group');

# Check the underlying data.
for my $key (qw(desc name)) {
    is($group->$key, $expected->{groups}[0]{$key}, "...group $key");
}

# Should be one phone.
my @phones = $user->phones;
is(scalar(@phones), 1, '...one phone');
my $phone = $phones[0];
isa_ok($phone, 'Net::Duo::Admin::Phone');

# Check the underlying simple data.
my @phone_keys = qw(
  phone_id number extension name postdelay predelay type platform activated
  sms_passcodes_sent
);
for my $key (@phone_keys) {
    is($phone->$key, $expected->{phones}[0]{$key}, "...phone $key");
}

# Check the capabilities, which is an array.
is_deeply(
    [$phone->capabilities],
    $expected->{phones}[0]{capabilities},
    '...phone capabilities'
);

# Should be one token.
my @tokens = $user->tokens;
is(scalar(@tokens), 1, '...one token');
my $token = $tokens[0];
isa_ok($token, 'Net::Duo::Admin::Token');

# Check the underlying data.
for my $key (qw(serial token_id type)) {
    is($token->$key, $expected->{tokens}[0]{$key}, "...token $key");
}

# Finished.  Tell Test::More that.
done_testing();
