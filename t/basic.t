#!/usr/bin/env perl

use Test::More 0.82;
use Test::Moose;
use Test::Fatal;

use Moose::Util 'does_role';

{
    package foo;
    use Moose;
    use namespace::autoclean;
    use MooseX::AbstractMethod;

    requires 'one';
}
{
    package bar;
    use Moose;

    extends 'foo';

    sub onetwo { 'whee!' }
}
{
    package baz;
    use Moose;

    extends 'foo';

    sub one { 'whee!' }
}


with_immutable {

    meta_ok('foo');
    meta_ok('bar');

    like(
        exception { bar->meta->make_immutable },
        qr/abstract methods have not been implemented/,
        'bar dies',
    );
    is(exception { baz->meta->make_immutable }, undef, 'baz lives');

} qw{ foo };

done_testing;
