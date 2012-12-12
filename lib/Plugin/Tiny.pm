#ABSTRACT: Even simpler than Plugin::Simple
package Plugin::Tiny;
use strict;
use warnings;
use Carp 'confess';
use Class::Load;
use Moose;
use namespace::autoclean;

has '_registry' => (    #href with phases and plugin objects
    is        => 'ro',
    isa       => 'HashRef[Object]',
    default   => sub { {} },
    init_args => undef,
);

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

Plugin::Tiny has less code than Plugin::Simple while almost providing the
same functionality.

A limitation of Plugin::Tiny is that each phase can have only one plugin. 
But you can create bundles of plugins if you hand the plugin system down to the
plugin. That way, you load multiple plugins for one phase, although you still
need distinct phase labels for each plugin.

  #in your core
  $self->plugins->register(
    phase=>'scan', 
    plugin=>$scan_plugin, 
    $args=>{plugins=>$self->plugins}
  );

  #in your $scan_plugin (acts as a bundle)
  has 'plugins'=>(is=>'ro', isa=>'Plugin::Tiny', required=>1); 
  $self->plugins->register (phase=>'Scan1', plugin=>'Plugin::Scan1'); 
  $self->plugins->register (phase=>'Scan2', plugin=>'Plugin::Scan2'); 
  
  my $scan1=$self->plugins->get('Scan1');
  $scan1->do_somthing(@args);  

You may want to standardize the methods in your plugins,e.g. by using a role. 
Perhaps you always want to require an execute method instead of do_something.
  
=method $plugin_system->register(phase=>$phase, plugin=>$plugin_class);  

Optionally, you can also specify a role which your plugin will have to be able 
to apply and args for the constructor, see Synopsis.

Returns the newly created plugin object on success.

=cut

sub register {
    my $self   = shift;
    my %args   = shift;
    my $plugin = $args{plugin} or confess "Need plugin";
    my $phase  = $args{phase} or confess "Need phase";
    my @args   = $args{args} ? @{$args{args}} : ();

    load_class($args{plugin});

    $self->{_registry}{$phase} = $plugin->new(@args);

    if (defined $args{role} && !$plugin->does($args{role})) {
        confess qq(Plugin doesn't plugin into role '$args{role}');
    }
    return $self->{_registry}{$phase};
}

=method my $plugin=$self->get_plugin ($phase);

=cut


sub get_plugin {
    my $self  = shift;
    my $phase = shift;
    return $self->{_registry}{$phase};
}

__PACKAGE__->meta->make_immutable;

1;