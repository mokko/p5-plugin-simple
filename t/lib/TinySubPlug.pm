package TinySubPlug;
use strict;
use warnings;
use Moose;
#has 'plugins' => (is => 'ro', isa => 'Plugin::Tiny', required => 1);

sub do_something {
    'a plugin that is loaded by another plugin';
}

1;
