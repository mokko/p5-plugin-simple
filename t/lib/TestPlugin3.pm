package TestPlugin3;

use strict;
use warnings;

use Moose;
with 'Plugin::Simple::Role::Plugin';

sub phase {'non-existing-phase'}
sub execute {
    my ($self,$core)=@_;
    die "Need myself" if (!$self);
    die "This test requires core" if (!$core);
    return "foo";
}

1;