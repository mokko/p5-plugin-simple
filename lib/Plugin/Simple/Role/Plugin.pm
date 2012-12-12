#ABSTRACT: Minimal plugin requirements
package Plugin::Simple::Role::Plugin;
{
  $Plugin::Simple::Role::Plugin::VERSION = '0.001';
}
use strict;
use warnings;
use Moose::Role;


has 'return' => (is=>'rw');



requires 'phase';


1;
__END__
=pod

=head1 NAME

Plugin::Simple::Role::Plugin - Minimal plugin requirements

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  package YourPlugin;
  use Moose;
  with 'Plugin::Simple::Role::Plugin';
  
  has 'core'=>(is=>'ro', isa=>'Object');
  
  sub phase {'phase1'};
  
  sub BUILD {
      my $self=shift;
      $self->core->do_something('bla');
      $self->return ('Hand something back to the core application');
  }
  
  1;

=head1 DESCRIPTION

It's up to you to decide what you hand to your plugins. In the example above I
hand the complete core applitation down to the plugin, including the plugin 
system. If the plugin has access to the plugin system it can initiate and 
execute new plugins. That's right. Plugins calling plugins. Of course, that's
a security risk, because the plugin knows all your secrets.

=head1 ATTRIBUTES

=head2

If your plugin wants to hand a return value back, put it in return. It accepts
all or nothing. Can be undefined. Can be reference, scalar, array, object etc.

=head2 phase

returns (label of) the phase of your plugin is part of, e.g.

  sub phase { 'phase_1'}

=head1 AUTHOR

Maurice Mengel <mauricemengel@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Maurice Mengel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

