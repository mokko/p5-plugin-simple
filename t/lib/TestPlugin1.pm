package TestPlugin1;

use strict;
use warnings;

#if it consumes a role it's automatically an object...
use Moose;
with 'Plugin::Simple::Role::Plugin';

#define a constructor that handles your arguments

sub phase {'Phase1'}

sub execute {
    my ($self) = @_;
    die "Need myself"             if (!$self);
    return 'bar';
}

1;
