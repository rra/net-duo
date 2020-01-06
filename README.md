# Net::Duo 1.02

[![No maintenance
intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/)
[![Build
status](https://travis-ci.org/rra/net-duo.svg?branch=master)](https://travis-ci.org/rra/net-duo)
[![CPAN
version](https://img.shields.io/cpan/v/Net-Duo.svg)](https://metacpan.org/release/Net-Duo)

Copyright 2015, 2018-2019 Russ Allbery <rra@cpan.org>.  Copyright 2014 The
Board of Trustees of the Leland Stanford Junior University.  This software
is distributed under a BSD-style license.  Please see the section
[License](#license) below for more information.

## Warning

**This package is orphaned.** You should use the Perl code provided by Duo
instead, since it will be more up-to-date with current features.  I no
longer maintain a large Duo deployment, and my current company uses Python
instead.  That said, I do still think this package provides a nicer object
framework for the Duo API in Perl; if you agree, please feel free to adopt
it and maintain it!

## Blurb

Net::Duo provides an object-oriented Perl interface for the Duo Security
REST APIs.  It attempts to abstract some of the API details and provide an
object-oriented view of the returned objects in order to make use of the
API in Perl code more natural than dealing with JSON data structures
directly.  Currently, some parts of the Auth and Admin APIs are
implemented alongside with generic methods to call any of the JSON-based
APIs.

## Description

[Duo Security](https://duosecurity.com/) is a cloud second-factor
authentication service that supports a wide variety of different
mechanisms for a user to establish a second authentication factor.  It is
intended to supplement local authentication systems, such as
password-based authentication, with an unrelated second factor: possession
of a device, or access to a phone.  Duo Security provides direct
integration with a variety of applications and a self-service web sign-up
interface, but for more control, it also provides several RESTful APIs
that can perform all possible actions on Duo accounts, users, and their
devices.

This module implements a client for the Duo REST APIs.  It differs from
the sample Perl implementation provided by Duo in that it attempts to wrap
the Duo data model and JSON information in Perl objects and provide
logical and convenient methods on those objects to make writing Perl
clients of Duo simpler and easier.  It tries to abstract portions of the
API, such as the endpoint URLs, that allow for more natural and less
cluttered Perl code than manipulating the JSON data structures directly.

The API implementation is currently incomplete and contains just the calls
required by Stanford's integration.  Only the Auth and Admin APIs are
implemented, and both are partial.  However, the Net::Duo `call`,
`call_json`, and `call_json_paged` methods can be used to make calls to
APIs that aren't fully implemented.

## Requirements

Perl 5.14 or later and Module::Build 0.28 or later are required to build
this module.  The following additional Perl modules are required to use
it:

* JSON
* HTTP::Message
* LWP::UserAgent 6.00 or later (part of libwww-perl)
* Perl6::Slurp
* Sub::Install
* URI::Escape (part of URI)

All are available on CPAN.

## Building and Installation

Net::Duo uses Module::Build and can be installed using the same process as
any other Module::Build module:

```
    perl Build.PL
    ./Build
    ./Build install
```

You will have to run the last command as root unless you're installing
into a local Perl module tree in your home directory.

## Testing

Net::Duo comes with a test suite, which you can run after building with:

```
    ./Build test
```

If a test fails, you can run a single test with verbose output via:

```
    ./Build test --test_files <path-to-test>
```

The following additional Perl modules will be used by the test suite if
present:

* Test::MinimumVersion
* Test::Perl::Critic
* Test::Pod
* Test::Pod::Coverage
* Test::Spelling
* Test::Strict
* Test::Synopsis

All are available on CPAN.  Those tests will be skipped if the modules are
not available.

To enable tests that don't detect functionality problems but are used to
sanity-check the release, set the environment variable `RELEASE_TESTING`
to a true value.  To enable tests that may be sensitive to the local
environment or that produce a lot of false positives without uncovering
many problems, set the environment variable `AUTHOR_TESTING` to a true
value.

## Support

The [Net::Duo web page](https://www.eyrie.org/~eagle/software/net-duo/)
will always have the current version of this package, the current
documentation, and pointers to any additional resources.

For bug tracking, use the [CPAN bug
tracker](https://rt.cpan.org/Dist/Display.html?Name=Net-Duo).  However,
please be aware that I tend to be extremely busy and work projects often
take priority.  I'll save your report and get to it as soon as I can, but
it may take me a couple of months.

## Source Repository

Net::Duo is maintained using Git.  You can access the current source on
[GitHub](https://github.com/rra/net-duo) or by cloning the repository at:

https://git.eyrie.org/git/perl/net-duo.git

or [view the repository on the
web](https://git.eyrie.org/?p=perl/net-duo.git).

The eyrie.org repository is the canonical one, maintained by the author,
but using GitHub is probably more convenient for most purposes.  Pull
requests are gratefully reviewed and normally accepted.  It's probably
better to use the CPAN bug tracker than GitHub issues, though, to keep all
Perl module issues in the same place.

## License

The Net::Duo package as a whole is covered by the following copyright
statement and license:

> Copyright 2015, 2018-2019
>     Russ Allbery <rra@cpan.org>
>
> Copyright 2014
>     The Board of Trustees of the Leland Stanford Junior University
>
> Permission is hereby granted, free of charge, to any person obtaining a
> copy of this software and associated documentation files (the "Software"),
> to deal in the Software without restriction, including without limitation
> the rights to use, copy, modify, merge, publish, distribute, sublicense,
> and/or sell copies of the Software, and to permit persons to whom the
> Software is furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
> THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
> FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
> DEALINGS IN THE SOFTWARE.

Some files in this distribution are individually released under different
licenses, all of which are compatible with the above general package
license but which may require preservation of additional notices.  All
required notices, and detailed information about the licensing of each
file, are recorded in the LICENSE file.

Files covered by a license with an assigned SPDX License Identifier
include SPDX-License-Identifier tags to enable automated processing of
license information.  See https://spdx.org/licenses/ for more information.

For any copyright range specified by files in this package as YYYY-ZZZZ,
the range specifies every single year in that closed interval.
