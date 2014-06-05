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

# Data keys that can use simple verification.
my @GROUP_KEYS = qw(desc name);
my @USER_KEYS  = qw(user_id username realname email status last_login notes);
my @TOKEN_KEYS = qw(serial token_id type);
my @PHONE_KEYS = qw(
  phone_id number extension name postdelay predelay type platform
  activated sms_passcodes_sent
);

##############################################################################
# Helper functions
##############################################################################

# Given a Net::Duo::Admin::User object and the data structure representation
# of the JSON for that user, check that all the data fields match.  Test
# results are reported via Test::More.
#
# $user     - The Net::Duo::Admin::User object
# $expected - The data structure representing that user
#
# Returns: undef
sub is_user {
    my ($user, $expected) = @_;

    # Check the object type.
    isa_ok($user, 'Net::Duo::Admin::User');

    # Check the top-level, simple data.  We can't just use is_deeply on the
    # top-level object because we've converted some of the underlying hashes
    # to other objects, so we walk specific keys and confirm they match.
    for my $key (@USER_KEYS) {
        is($user->$key, $expected->{$key}, "...$key");
    }

    # Iterate through the groups.
    my @groups = $user->groups;
    is(scalar(@groups), scalar(@{ $expected->{groups} }), '...group count');
    for my $i (0 .. $#groups) {
        my $seen_group     = $groups[$i];
        my $expected_group = $expected->{groups}[$i];

        # Check object type.
        isa_ok($seen_group, 'Net::Duo::Admin::Group');

        # Check the underlying data.
        for my $key (@GROUP_KEYS) {
            is($seen_group->$key, $expected_group->{$key}, "...group $i $key");
        }
    }

    # Iterate through the phones.
    my @phones = $user->phones;
    is(scalar(@phones), scalar(@{ $expected->{phones} }), '...phone count');
    for my $i (0 .. $#phones) {
        my $seen_phone     = $phones[$i];
        my $expected_phone = $expected->{phones}[$i];

        # Check object type.
        isa_ok($seen_phone, 'Net::Duo::Admin::Phone');

        # Check the underlying simple data.
        for my $key (@PHONE_KEYS) {
            is($seen_phone->$key, $expected_phone->{$key}, "...phone $i $key");
        }

        # Check the capabilities, which is an array.
        is_deeply(
            [$seen_phone->capabilities],
            $expected_phone->{capabilities},
            '...phone capabilities'
        );
    }

    # Iterate through the tokens.
    my @tokens = $user->tokens;
    is(scalar(@tokens), scalar(@{ $expected->{tokens} }), '...token count');
    for my $i (0 .. $#tokens) {
        my $seen_token     = $tokens[$i];
        my $expected_token = $expected->{tokens}[$i];

        # Check object type.
        isa_ok($seen_token, 'Net::Duo::Admin::Token');

        # Check the underlying data.
        for my $key (@TOKEN_KEYS) {
            is($seen_token->$key, $expected_token->{$key}, "...token $i $key");
        }
    }
    return;
}

##############################################################################
# Tests
##############################################################################

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

# Verify that the returned user is correct.
my $raw      = slurp('t/data/responses/users.json');
my $expected = $json->decode($raw)->[0];
is_user($users[0], $expected);

# Now, try a user call with a specified username.
$mock->expect(
    {
        method        => 'GET',
        uri           => '/admin/v1/users',
        content       => { username => 'jdoe' },
        response_file => 't/data/responses/user.json',
    }
);
note('Testing users endpoint with search for jdoe');
my $user = $duo->user('jdoe');

# Verify that the returned user is correct.
$raw      = slurp('t/data/responses/user.json');
$expected = $json->decode($raw)->[0];
is_user($user, $expected);

# Finished.  Tell Test::More that.
done_testing();
