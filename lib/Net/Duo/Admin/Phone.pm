# Representation of a single Duo phone for the Admin API.
#
# This class wraps the Duo representation of a single Duo phone, as returned
# by (for example) the Admin /phones REST endpoint.

package Net::Duo::Admin::Phone 1.00;

use 5.014;
use strict;
use warnings;

use parent qw(Net::Duo::Object);

use Net::Duo::Admin::User;

# Data specification for converting JSON into our object representation.  See
# the Net::Duo::Object documentation for syntax information.
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _fields {
    return {
        activated          => 'simple',
        capabilities       => 'array',
        extension          => ['simple', 'set'],
        name               => ['simple', 'set'],
        number             => ['simple', 'set'],
        phone_id           => 'simple',
        platform           => ['simple', 'set'],
        postdelay          => ['simple', 'set'],
        predelay           => ['simple', 'set'],
        sms_passcodes_sent => 'simple',
        type               => ['simple', 'set'],
        users              => 'Net::Duo::Admin::User',
    };
}
## use critic

# Install our accessors.
Net::Duo::Admin::Phone->install_accessors;

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
    return $class->SUPER::create($duo, '/admin/v1/phones', $data_ref);
}

# Commit any changed data and refresh the object from Duo.
#
# $self - The Net::Duo::Admin::Phone object to commit changes for
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem updating the object
sub commit {
    my ($self) = @_;
    return $self->SUPER::commit("/admin/v1/phones/$self->{phone_id}");
}

# Delete the phone from Duo.  After this call, the object should be treated as
# read-only since it can no longer be usefully updated.
#
# $self - The Net::Duo::Admin::Phone object to delete
#
# Returns: undef
#  Throws: Net::Duo::Exception on any problem deleting the object
## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub delete {
    my ($self) = @_;
    $self->{_duo}->call_json('DELETE', "/admin/v1/phones/$self->{phone_id}");
    return;
}
## use critic

1;
__END__

=for stopwords
Allbery MERCHANTABILITY NONINFRINGEMENT SMS passcodes sublicense postdelay
predelay

=head1 NAME

Net::Duo::Admin::Phone - Representation of a Duo phone

=head1 SYNOPSIS

    my $decoded_json = get_json();
    my $phone = Net::Duo::Admin::Phone->new($decoded_json);
    say $phone->number;

=head1 DESCRIPTION

A Net::Duo::Admin::Phone object is a Perl representation of a Duo phone as
returned by the Duo Admin API, usually via the phones() method or nested
in a user returned by the users() method.  It contains various information
about a phone.

=head1 CLASS METHODS

=over 4

=item create(DUO, DATA)

Creates a new phone in Duo and returns the resulting user as a new
Net::Duo::Admin::Phone object.  DUO is the Net::Duo object that should be
used to perform the creation.  DATA is a reference to a hash with the
following keys:

=over 4

=item extension

The extension.  Optional.

=item name

The name of the phone.  Optional.

=item number

The phone number.  Optional.

=item platform

The platform of phone for Duo Mobile, or C<unknown> for a generic phone
type.  For the list of valid values, see the Duo Admin API documentation.
Optional.

=item postdelay

The time (in seconds) to wait after the extension is dialed and before the
speaking the prompt.  Optional.

=item predelay

The time (in seconds) to wait after the number picks up and before dialing
the extension.  Optional.

=item type

The type of the phone.  See the L</type()> method below for the possible
values.  Optional.

=back

=item new(DUO, DATA)

Creates a new Net::Duo::Admin::Phone object from a full data set.  DUO is
the Net::Duo object that should be used for any further actions on this
object.  DATA should be the data structure returned by the Duo REST API
for a single user, after JSON decoding.

=back

=head1 INSTANCE ACTION METHODS

=over 4

=item commit()

Commit all changes made via the set_*() methods to Duo.  Until this method
is called, any changes made via set_*() are only internal to the object
and not reflected in Duo.

After commit(), the internal representation of the object will be
refreshed to match the new data returned by the Duo API for that object.
Therefore, other fields of the object may change after commit() if some
other user has changed other, unrelated fields in the object.

It's best to think of this method as a synchronize operation: changed data
is written back, overwriting what's in Duo, and unchanged data may be
overwritten by whatever is currently in Duo, if it is different.

=item delete()

Delete this phone from Duo.  After successful completion of this call, the
Net::Duo::Admin::Phone object should be considered read-only, since no
further changes to the object can be meaningfully sent to Duo.

=back

=head1 INSTANCE DATA METHODS

Some fields have set_*() methods.  Those methods replace the value of the
field in its entirety with the new value passed in.  This change is only
made locally in the object until commit() is called.

=over 4

=item activated()

Whether the phone has been activated for Duo Mobile.

=item capabilities()

A list of phone capabilities, chosen from the following values:

=over 4

=item C<push>

The device is activated for Duo Push.

=item C<phone>

The device can receive phone calls.

=item C<sms>

The device can receive batches of SMS passcodes.

=back

=item extension()

=item set_extension(EXTENSION)

The extension for this phone, if any.

=item name()

=item set_name(NAME)

The name of this phone.

=item number()

=item set_number(NUMBER)

The number for this phone, without any extension.

=item phone_id()

The unique ID of this phone as generated by Duo on phone creation.

=item platform()

=item set_platform(PLATFORM)

The platform of phone for Duo Mobile, or C<unknown> for a generic phone
type.  For the list of valid values, see the Duo Admin API documentation.

=item postdelay()

=item set_postdelay(POSTDELAY)

The time (in seconds) to wait after the extension is dialed and before the
speaking the prompt.

=item predelay()

=item set_predelay(PREDELAY)

The time (in seconds) to wait after the number picks up and before dialing
the extension.

=item sms_passcodes_sent()

Whether SMS passcodes have been sent to this phone.

=item type()

=item set_type(TYPE)

The type of phone, chosen from C<unknown>, C<mobile>, or C<landline>.

=item users()

The users associated with this phone as a list of Net::Duo::Admin::User
objects.

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

L<Duo Admin API for phones|https://www.duosecurity.com/docs/adminapi#phones>

=cut
