#ABSTRACT: Even simpler than Plugin::Simple
package Plugin::Tiny;
{
  $Plugin::Tiny::VERSION = '0.001';
}
use strict;
use warnings;
use Carp 'confess';
use Class::Load 'load_class';
use Moose;
use namespace::autoclean;

has '_registry' => (    #href with phases and plugin objects
    is        => 'ro',
    isa       => 'HashRef[Object]',
    default   => sub { {} },
    init_arg => undef,
);


sub register {
    my $self   = shift;
    my %args   = @_;
    my $plugin = delete $args{plugin} or confess "Need plugin";
    my $phase  = delete $args{phase} or confess "Need phase";
    my $role= delete $args{role} if $args{role};

    load_class($plugin) or confess "Can't load $plugin";
    $self->{_registry}{$phase} = $plugin->new(%args);

    if ($role && !$plugin->does($role)) {
        confess qq(Plugin doesn't plugin into role '$role');
    }
    return $self->{_registry}{$phase};
}



sub get_plugin {
    my $self  = shift;
    my $phase = shift;
    return $self->{_registry}{$phase};
}

__PACKAGE__->meta->make_immutable;

1;
__END__
=pod

=head1 NAME

Plugin::Tiny - Even simpler than Plugin::Simple

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Moose; 
  use Plugin::Tiny; 
  has 'plugins'=>(
    is=>'ro',
    isa=>'Plugin::Tiny', 
    default=>sub{Plugin::Tiny->new()}
  );
  
  #load plugin_class and perhaps phase from your configuration
  #register your plugin  
  $self->plugins->register(
    phase=>$phase,         #required
    plugin=>$plugin_class, #required
    role=>$role,           #optional
    args=>\@_              #optional
  );

  #execute your plugin
  my $plugin=$self->get_plugin ($phase); 
  $plugin->do_something(@args);  

=head1 DESCRIPTION

Plugin::Tiny has less code than Plugin::Simple with almost the same 
functionality.

A limitation of Plugin::Tiny is that each phase can have only one plugin. 
But you can still create bundles of plugins if you hand the plugin system down 
to the plugin. That way, you can load multiple plugins for one phase; you 
still need distinct phase labels for each plugin.

  #in your core
  $self->plugins->register(
    phase=>'scan', 
    plugin=>$scan_plugin, 
    plugins=>$self->plugins, #plugin system
  );

  #in your $scan_plugin (acts as a bundle)
  has 'plugins'=>(is=>'ro', isa=>'Plugin::Tiny', required=>1); 
  $self->plugins->register (phase=>'Scan1', plugin=>'Plugin::Scan1'); 
  $self->plugins->register (phase=>'Scan2', plugin=>'Plugin::Scan2'); 
  
  my $scan1=$self->plugins->get('Scan1');
  $scan1->do_somthing(@args);  

You may want to standardize the methods in your plugins,e.g. by using a role. 
Perhaps you always want to require an execute method instead of do_something.

=head1 METHODS

=head2 $plugin_system->register(phase=>$phase, plugin=>$plugin_class);  

Optionally, you can also specify a role which your plugin will have to be able 
to apply. Remaining key value pairs are passed down to the plugin constructor: 

  $plugin_system->register (
    phase=>$phase, 
    plugin=>$plugin,
    role=>$role,
    plugins=>$plugin_system,
    args=>$more_args,
  );

A side-effect of this is that your plugin cannot use 'phase', 'plugin', 'role' 
as named arguments.

Returns the newly created plugin object on success. Confesses on error.

=head2 my $plugin=$self->get_plugin ($phase);

=head1 AUTHOR

Maurice Mengel <mauricemengel@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Maurice Mengel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

