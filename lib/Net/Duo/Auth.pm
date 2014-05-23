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

##############################################################################
# Auth API methods
##############################################################################

# Confirm that authentication works properly.
#
# Returns: Server time in seconds since UNIX epoch
#  Throws: Net::Duo::Exception on failure
sub check {
    my ($self) = @_;

    # Make the Duo call and get the decoded result.
    my $result = $self->call_json('GET', '/auth/v2/check');
    return $result->{time};
}

1;
__END__

=for stopwords
Allbery Auth MERCHANTABILITY NONINFRINGEMENT sublicense

=head1 NAME

Net::Duo::Auth - Perl interface for the Duo Auth API

=head1 SYNOPSIS

    my $duo = Net::Duo::Auth->new({ key_file => '/path/to/keys.json' });
    my $timestamp = $duo->check;

=head1 REQUIREMENTS

Perl 5.14 or later and the modules LWP (also known as libwww-perl), JSON,
and Perl6::Slurp, all of which are available from CPAN.

=head1 DESCRIPTION

Net::Duo::Auth is an implementation of the Duo Auth REST API for Perl.
Method calls correspond to endpoints in the REST API.  Its goal is to
provide a native, natural interface for all Duo operations in the API from
inside Perl, while abstracting away as many details of the API as can be
reasonably handled automatically.

Currently, only a tiny number of available methods are implemented.

For calls that return complex data structures, the return from the call
will generally be an object in the Net::Duo namespace.  These objects all
have methods matching the name of the field in the Duo API documentation
that returns that field value.  Where it makes sense, there will also be
a method with the same name but with C<set_> prepended that changes that
value.  No changes are made to the Duo record itself until the commit()
method is called on the object, which will make the underlying Duo API
call to update the data.

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

=item check()

Calls the check endpoint.  This can be used as a simple check that all of
the integration arguments are correct and the client can authenticate to
the Duo authentication API.  On success, it returns the current time on
the Duo server in seconds since UNIX epoch.

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
