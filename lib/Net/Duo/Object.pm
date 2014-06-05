# Helper base class for Duo objects.
#
# The Duo API contains a variety of objects, represented as JSON objects with
# multiple fields.  This objects often embed other objects inside them.  To
# provide a nice Perl API with getters, setters, and commit and delete methods
# on individual objects, we want to wrap these Duo REST API objects in Perl
# classes.
#
# This module serves as a base class for such objects and does the dirty work
# of constructing an object from decoded JSON data and building the accessors
# automatically from a field specification.

package Net::Duo::Object 1.00;

use 5.014;
use strict;
use warnings;

use Carp qw(croak);
use Sub::Install;

# Create a new Net::Duo object.  This instructor can be inherited by all
# object classes.  It takes the decoded JSON and uses the field specification
# for the object to construct an object via deep copying.
#
# The child class must provide a static method fields() that returns a field
# specification.  See the documentation for more details.
#
# $class    - Class of object to create
# $duo      - Net::Duo object to use for further API calls on this user
# $data_ref - User data as a reference to a hash (usually decoded from JSON)
#
# Returns: Newly-created object
sub new {
    my ($class, $duo, $data_ref) = @_;

    # Retrieve the field specification for this object.
    my $fields = $class->_fields;

    # Make a deep copy of the data following the field specification.
    my $self = { _duo => $duo };
    for my $field (keys %{$fields}) {
        my $type  = $fields->{$field};
        my $value = $data_ref->{$field};
        if ($type eq 'simple') {
            $self->{$field} = $value;
        } elsif ($type eq 'array') {
            $self->{$field} = [@{$value}];
        } elsif (defined($value)) {
            my @objects;
            for my $object (@{$value}) {
                push(@objects, $type->new($duo, $object));
            }
            $self->{$field} = \@objects;
        }
    }

    # Bless and return the new object.
    bless($self, $class);
    return $self;
}

# Create all the accessor methods for the object fields.  This method is
# normally called via code outside of any method in the object class so that
# it is run when the class is first imported.
#
# The child class must provide a static method fields() that returns a field
# specification.  See the documentation for more details.
#
# $class - Class whose accessors we're initializing
#
# Returns: undef
sub install_accessors {
    my ($class) = @_;

    # Retrieve the field specification for this object.
    my $fields = $class->_fields;

    # Create an accessor for each one.
    for my $field (keys %{$fields}) {
        my $type = $fields->{$field};

        # For fields containing arrays, return a copy of the array instead
        # of the reference to the internal data structure in the object,
        # preventing client manipulation of our internals.
        my $code;
        if ($type eq 'simple') {
            $code = sub { my $self = shift; return $self->{$field} };
        } else {
            $code = sub { my $self = shift; return @{ $self->{$field} } };
        }

        # Create and install the accessor.
        my $spec = { code => $code, into => $class, as => $field };
        Sub::Install::install_sub($spec);
    }
    return;
}

1;
__END__

=for stopwords
Allbery undef MERCHANTABILITY NONINFRINGEMENT sublicense getters

=head1 NAME

Net::Duo::Object - Helper base class for Duo objects

=head1 SYNOPSIS

    package Net::Duo::Admin::Token 1.00;

    use parent qw(Net::Duo::Object);

    sub fields {
        return {
            token_id => 'simple',
            type     => 'simple',
            serial   => 'simple',
            users    => 'Net::Duo::Admin::User',
        };
    }

    Net::Duo::Admin::Token->install_accessors;

=head1 REQUIREMENTS

Perl 5.14 or later and the module Sub::Install, which is available from
CPAN.

=head1 DESCRIPTION

The Duo API contains a variety of objects, represented as JSON objects
with multiple fields.  This objects often embed other objects inside them.
To provide a nice Perl API with getters, setters, and commit and delete
methods on individual objects, we want to wrap these Duo REST API objects
in Perl classes.

This module serves as a base class for such objects and does the dirty
work of constructing an object from decoded JSON data and building the
accessors automatically from a field specification.

This class should normally be considered an internal implementation detail
of the Net::Duo API.  Only developers of the Net::Duo modules should need
to worry about it.  Callers can use other Net::Duo API objects without
knowing anything about how this class works.

=head1 FIELD SPECIFICATION

Any class that wants to use Net::Duo::Object to construct itself must
provide a field specification.  This is a data structure that describes
all the data fields in that object.  It is used by the generic
Net::Duo::Object constructor to build the Perl data structure for an
object, and by the install_accessors() class method to create the
accessors for the class.

The client class must provide a class method named _fields() that returns
a reference to a hash.  The keys of the hash are the field names of the
data stored in an object of that class.  The values specify the type of
data stored in that field and must be chosen from the following:

=over 4

=item C<array>

An array of simple text, number, or boolean values.

=item C<simple>

A simple text, number, or boolean field,

=item I<class>

The name of a class.  This field should then contain an array of zero or
more instances of that class, and the constructor for that class will be
called with the resulting structures.

=back

=head1 CLASS METHODS

=over 4

=item install_accessors()

Using the field specification, creates accessor functions for each data
field that return copies of the data stored in that field, or undef if
there is no data.

=item new(DATA)

A general constructor for Net::Duo objects.  Takes a reference to a hash,
which contains the data for an object of the class being constructed.
Using the field specification for that class, the data will be copied out
of the object into a Perl data structure, converting nested objects to
other Net::Duo objects as required.

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

L<Net::Duo>

=cut
