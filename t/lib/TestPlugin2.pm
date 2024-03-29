package TestPlugin2;    ##OO-Plugin

use strict;
use warnings;
use Moose;
with 'Plugin::Simple::Role::Plugin';

has 'foo' => (is => 'ro', isa => 'Str', required => 1);

sub phase {'Phase2'}

sub execute {
    my $self = shift or die "Need myself";
    $self->return(undef);
}

1;
