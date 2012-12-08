#ABSTRACT: Minimal plugin requirements
package Plugin::Simple::Role::Plugin;
use strict;
use warnings;
use Moose::Role;

=head2 phase

returns (label of) the phase of your plugin is part of, e.g.

  sub phase { 'phase_1'}

=cut

requires 'phase';

=head2 $plugin->execute ($core);

Plugin:Simple will call execute ($core) when you do
  $plugins->execute ($phase, $core)
from your app.

=cut

requires 'execute';

=method $self->plugin_package

returns the plugin's package name. 

=cut

sub plugin_package {
    return __PACKAGE__;
}

1;