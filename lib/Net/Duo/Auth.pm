# Perl interface for the Duo Auth API.
#
# This Perl module collection provides a Perl interface to the Auth API
# integration for the Duo multifactor authentication service
# (https://www.duosecurity.com/).  It differs from the Perl API sample code in
# that it wraps all the returned data structures in objects with method calls,
# abstracts some of the API details, and throws rich exceptions rather than
# requiring the caller deal with JSON data structures directly.

package Net::Duo::Auth 1.00;

use 5.014;
use strict;
use warnings;

use parent qw(Net::Duo);

# All dies are of constructed objects, which perlcritic misdiagnoses.
## no critic (ErrorHandling::RequireCarping)

##############################################################################
# Auth API methods
##############################################################################

# Confirm that authentication works properly.
#
# $self - The Net::Duo::Auth object
#
# Returns: Server time in seconds since UNIX epoch
#  Throws: Net::Duo::Exception on failure
sub check {
    my ($self) = @_;
    my $result = $self->call_json('GET', '/auth/v2/check');
    return $result->{time};
}

# Send one or more passcodes (depending on Duo configuration) to a user via
# SMS.  This should always succeed, so any error results in an exception.
#
# $self     - The Net::Duo::Auth object
# $username - The username to send SMS passcodes to
# $device   - ID of the device to which to send passcodes (optional)
#
# Returns: undef
#  Throws: Net::Duo::Exception on failure
sub send_sms_passcodes {
    my ($self, $username, $device) = @_;
    my $data = {
        username => $username,
        factor   => 'sms',
        device   => $device // 'auto',
    };
    my $result = $self->call_json('POST', '/auth/v2/auth', $data);
    if ($result->{status} ne 'sent') {
        my $status  = $result->{status};
        my $message = $result->{status_msg};
        my $error   = "sending SMS passcodes returned $status: $message";
        die Net::Duo::Exception->protocol($error, $result);
    }
    return;
}

# Validate an out-of-band method, such as Duo Push or a phone call.
#
# $self     - The Net::Duo::Auth object
# $username - The username to attempt an auth for
#
# Returns: Transaction id, which can be checked on with auth_status
#  Throws: Net::Duo::Exception on failure
sub validate_out_of_band {
    my ($self, $username) = @_;
    my $data = {
        username => $username,
        factor   => 'auto',
        device   => 'auto',
        async    => 1,
    };
    my $result = $self->call_json('POST', '/auth/v2/auth', $data);
    return $result->{txid};
}

# Validate a passcode given to us by a user.
#
# $self     - The Net::Duo::Auth object
# $username - The username to check against
# $passcode - The passcode given by the user
#
# Returns: Status of the auth.  Will be 'allow' on success.
#  Throws: Net::Duo::Exception on failure
sub validate_passcode {
    my ($self, $username, $passcode) = @_;
    my $data = {
        username => $username,
        factor   => 'passcode',
        passcode => $passcode,
    };
    my $result = $self->call_json('POST', '/auth/v2/auth', $data);
    return $result->{status};
}

# Check on the current status of a user auth request that requires a user
# response, such as a phone call or Duo Push.
#
# $self           - The Net::Duo::Auth object
# $transaction_id - Transaction id for the auth, given at auth attempt
#
# Returns: Status of the auth.  Will be 'allow' on success.
#  Throws: Net::Duo::Exception on failure
sub auth_status {
    my ($self, $transaction_id) = @_;
    my $data = { txid => $transaction_id };
    my $result = $self->call_json('GET', '/auth/v2/auth_status', $data);
    return $result->{result};
}

1;
__END__

=for stopwords
Allbery Auth MERCHANTABILITY NONINFRINGEMENT sublicense SMS passcode
passcodes

=head1 NAME

Net::Duo::Auth - Perl interface for the Duo Auth API

=head1 SYNOPSIS

    my $duo = Net::Duo::Auth->new({ key_file => '/path/to/keys.json' });
    my $timestamp = $duo->check;

=head1 REQUIREMENTS

Perl 5.14 or later and the modules LWP (also known as libwww-perl), JSON,
Perl6::Slurp, and Sub::Install, all of which are available from CPAN.

=head1 DESCRIPTION

Net::Duo::Auth is an implementation of the Duo Auth REST API for Perl.
Method calls correspond to endpoints in the REST API.  Its goal is to
provide a native, natural interface for all Duo operations in the API from
inside Perl, while abstracting away as many details of the API as can be
reasonably handled automatically.

Currently, only a tiny number of available methods are implemented.

For calls that return complex data structures, the return from the call
will generally be an object in the Net::Duo::Auth namespace.  These
objects all have methods matching the name of the field in the Duo API
documentation that returns that field value.  Where it makes sense, there
will also be a method with the same name but with C<set_> prepended that
changes that value.  No changes are made to the Duo record itself until
the commit() method is called on the object, which will make the
underlying Duo API call to update the data.

On failure, all methods throw a Net::Duo::Exception object.  This can be
interpolated into a string for a simple error message, or inspected with
method calls for more details.  This is also true of all methods in all
objects in the Net::Duo namespace.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new Net::Duo::Auth object, which is used for all subsequent
calls.  This constructor is inherited from Net::Duo.  See L<Net::Duo> for
documentation of the possible arguments.

=back

=head1 INSTANCE METHODS

=over 4

=item auth_status(ID)

Calls the Duo C<auth_status> endpoint.  This is used to check the current
status of an authentication attempt that cannot be immediately verified,
such as a Duo Push or phone call.  On success, it returns the current
result for the authentication attempt.  C<allow> or C<deny> are simple
success or failure, but C<waiting> denotes the attempt still being in
progress and so the calling program should continue to check back.

=item check()

Calls the Duo C<check> endpoint.  This can be used as a simple check that
all of the integration arguments are correct and the client can
authenticate to the Duo authentication API.  On success, it returns the
current time on the Duo server in seconds since UNIX epoch.

=item send_sms_passcodes(USERNAME[, DEVICE])

Send a new batch of passcodes to the specified user via SMS.  By default,
the passcodes will be sent to the first SMS-capable device (the Duo
C<auto> behavior).  The optional second argument specifies a device ID to
which to send the passcodes.  Any failure will result in an exception.

=item validate_out_of_band(USERID)

Calls the Duo C<auth> endpoint and requests an asynchronous
authentication.  This requests an out-of-band user authentication attempt
(Duo Push or phone call), that will require the user to respond on their
phone or device.  On success, it will return the transaction ID for the
authentication attempt.  This can be used with auth_status() later to
determine the final outcome of the authentication.

=item validate_passcode(USERID, PASSCODE)

Calls the Duo C<auth> endpoint.  This attempts to validate a passcode
against a user account to see if the user can successfully log in.  On
success, it returns the status of the authentication attempt from Duo.

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

L<Duo Auth API|https://www.duosecurity.com/docs/authapi>

=cut
