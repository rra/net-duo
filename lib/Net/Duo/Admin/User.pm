# Representation of a single Duo user for the Admin API.
#
# This class wraps the Duo representation of a single Duo user, as returned by
# (for example) the Admin /users REST endpoint.

package Net::Duo::Admin::User 1.00;

use 5.014;
use strict;
use warnings;

use parent qw(Net::Duo::Object);

use Net::Duo;
use Net::Duo::Admin::Group;
use Net::Duo::Admin::Phone;
use Net::Duo::Admin::Token;
use Net::Duo::Exception;

# Data specification for converting JSON into our object representation.  See
# the Net::Duo::Object documentation for syntax information.
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _fields {
    return {
        user_id    => 'simple',
        username   => 'simple',
        realname   => 'simple',
        email      => 'simple',
        status     => 'simple',
        groups     => 'Net::Duo::Admin::Group',
        last_login => 'simple',
        notes      => 'simple',
        phones     => 'Net::Duo::Admin::Phone',
        tokens     => 'Net::Duo::Admin::Token',
    };
}
## use critic

# Install our accessors.
Net::Duo::Admin::User->install_accessors;

# Override the create method to add the appropriate URI.
#
# $class    - Class of object to create
# $duo      - Net::Duo object to use to create the object
# $data_ref - Data for new object as a reference to a hash
#
# Returns: Newly-created object
#  Throws: Net::Duo::Exception on any problem creating the object
sub create {
    my ($class, $duo, $data_ref) = @_;
    return $class->SUPER::create($duo, '/admin/v1/users', $data_ref);
}

# Add a phone to this user.  All existing phones will be left unchanged.
#
# $self  - The Net::Duo::Admin::User object to modify
# $phone - The Net::Duo::Admin::Phone object to add
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem adding the phone
## no critic (ErrorHandling::RequireCarping)
sub add_phone {
    my ($self, $phone) = @_;
    if (!$phone->isa('Net::Duo::Admin::Phone')) {
        die Net::Duo::Exception->internal('invalid argument to add_phone');
    }
    my $uri = "/admin/v1/users/$self->{user_id}/phones";
    $self->{_duo}->call_json('POST', $uri, { phone_id => $phone->phone_id });
    return;
}
## use critic

# Add a token to this user.  All existing tokens will be left unchanged.
#
# $self  - The Net::Duo::Admin::User object to modify
# $token - The Net::Duo::Admin::Token object to add
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem adding the phone
## no critic (ErrorHandling::RequireCarping)
sub add_token {
    my ($self, $token) = @_;
    if (!$token->isa('Net::Duo::Admin::Token')) {
        die Net::Duo::Exception->internal('invalid argument to add_token');
    }
    my $uri = "/admin/v1/users/$self->{user_id}/tokens";
    $self->{_duo}->call_json('POST', $uri, { token_id => $token->token_id });
    return;
}
## use critic

# Delete the user from Duo.  After this call, the object should be treated as
# read-only since it can no longer be usefully updated.
#
# $self - The Net::Duo::Admin::User object to delete
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem deleting the object
## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub delete {
    my ($self) = @_;
    $self->{_duo}->call_json('DELETE', "/admin/v1/users/$self->{user_id}");
    return;
}
## use critic

# Remove a phone from this user.  Other phones will be left unchanged.
#
# $self  - The Net::Duo::Admin::User object to modify
# $phone - The Net::Duo::Admin::Phone object to remove
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem adding the phone
## no critic (ErrorHandling::RequireCarping)
sub remove_phone {
    my ($self, $phone) = @_;
    if (!$phone->isa('Net::Duo::Admin::Phone')) {
        die Net::Duo::Exception->internal('invalid argument to remove_phone');
    }
    my $uri = "/admin/v1/users/$self->{user_id}/phones/" . $phone->phone_id;
    $self->{_duo}->call_json('DELETE', $uri);
    return;
}
## use critic

# Remove a token from this user.  Other tokens will be left unchanged.
#
# $self  - The Net::Duo::Admin::User object to modify
# $token - The Net::Duo::Admin::Token object to remove
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem adding the phone
## no critic (ErrorHandling::RequireCarping)
sub remove_token {
    my ($self, $token) = @_;
    if (!$token->isa('Net::Duo::Admin::Token')) {
        die Net::Duo::Exception->internal('invalid argument to remove_token');
    }
    my $uri = "/admin/v1/users/$self->{user_id}/tokens/" . $token->token_id;
    $self->{_duo}->call_json('DELETE', $uri);
    return;
}
## use critic

1;
__END__

=for stopwords
Allbery MERCHANTABILITY NONINFRINGEMENT sublicense realname

=head1 NAME

Net::Duo::Admin::User - Representation of a Duo user

=head1 SYNOPSIS

    my $decoded_json = get_json();
    my $user = Net::Duo::Admin::User->new($decoded_json);
    say $user->realname;

=head1 DESCRIPTION

A Net::Duo::Admin::User object is a Perl representation of a Duo user as
returned by the Duo Admin API, usually via the users() method.  It contains
various information about the user, including their groups, phones, and
tokens.

=head1 CLASS METHODS

=over 4

=item create(DUO, DATA)

Creates a new user in Duo and returns the resulting user as a new
Net::Duo::Admin::User object.  DUO is the Net::Duo object that should be
used to perform the creation.  DATA is a reference to a hash with the
following keys:

=over 4

=item email

The email address of this user.  Optional.

=item notes

Notes about this user.  Optional.

=item realname

The real name of this user.  Optional.

=item status

The status of this user.  See the L</status()> method below for the
possible values.  Optional, and will be set to C<active> if no value
is given.

=item username

The name of the user to create.  This should be unique within this Duo
account and can be used to retrieve the user object again using the
user() method of Net::Duo::Admin.  Required.

=back

=item new(DUO, DATA)

Creates a new Net::Duo::Admin::User object from a full data set.  DUO is
the Net::Duo object that should be used for any further actions on this
object.  DATA should be the data structure returned by the Duo REST API
for a single user, after JSON decoding.

=back

=head1 INSTANCE ACTION METHODS

=over 4

=item add_phone(PHONE)

Associate the Net::Duo::Admin::Phone object PHONE with this user.  Other
phones associated with this user will be left unchanged.

=item add_token(TOKEN)

Associate the Net::Duo::Admin::Token object TOKEN with this user.  Other
tokens associated with this user will be left unchanged.

=item delete()

Delete this user from Duo.  After successful completion of this call,
the Net::Duo::Admin::User object should be considered read-only, since no
further changes to the object can be meaningfully sent to Duo.

=item remove_phone(PHONE)

Disassociate the Net::Duo::Admin::Phone object PHONE from this user.  Other
phones associated with this user will be left unchanged.

=item remove_token(TOKEN)

Disassociate the Net::Duo::Admin::Token object TOKEN from this user.  Other
tokens associated with this user will be left unchanged.

=back

=head1 INSTANCE DATA METHODS

=over 4

=item email()

The user's email address.

=item groups()

List of groups to which this user belongs, as Net::Duo::Admin::Group
objects.

=item last_login()

The last time this user logged in, as a UNIX timestamp, or undef if the
user has not logged in.

=item notes()

Notes about this user.

=item phones()

List of phones this user can use, as Net::Duo::Admin::Phone objects.

=item realname()

The user's real name.

=item status()

One of the following values:

=over 4

=item C<active>

The user must complete secondary authentication.

=item C<bypass>

The user will bypass secondary authentication after completing primary
authentication.

=item C<disabled>

The user will not be able to log in.

=item C<locked out>

The user has been automatically locked out due to excessive authentication
attempts.

=back

=item tokens()

List of tokens this user can use, as Net::Duo::Admin::Token objects.

=item user_id()

The unique ID of this user as generated by Duo on user creation.

=item username()

The username of this user.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 The Board of Trustees of the Leland Stanford Junior
University

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

L<Net::Duo::Admin>

L<Duo Admin API for users|https://www.duosecurity.com/docs/adminapi#users>

=cut
