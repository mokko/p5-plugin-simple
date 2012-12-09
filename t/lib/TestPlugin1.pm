package TestPlugin1;

use strict;
use warnings;
use Moose;
with 'Plugin::Simple::Role::Plugin';

sub phase {'Phase1'}

sub BUILD {
    my $self = shift or die "Need myself";
    $self->return('bar');
}

1;
