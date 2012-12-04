#ABSTRACT: Simply make your app pluggable
package Plugin::Simple;
use strict;
use warnings;
use Moose;
use Carp 'confess';
use Class::Load qw(load_class);

=head1 SYNOPSIS

  package YourPlugin;
  use Moose;                           
  with 'Plugin::Simple::Role::Plugin'; 

  sub phase {'foo'}
  
  sub execute {
      my ($self, $core)=@_; #receive what you hand over in execute below
      #do something
  }

  package YourApp;
  use Plugin::Simple;

  #during configuration 
  $plugins=Plugin::Simple->new(phases=>['Phase1', 'Phase2']); 

  #registers p under its phase & load/use it; $options from Load::Class 
  $plugins->register ($plugin,\%options);   

  #later during a phase: execute all plugins in this phase
  @p=$plugins->execute ($phase, $core); 
  foreach my $plugin (@p){
    my ($obj, $ret)=$plugins->return_value($plugin);
  }

=attr   
  $aref=$plugins->phases;  #getter

Getter returns arrayRef with all phase labels. 

Note that order of phases has no impact on when they're called. It's up the app 
which makes use of Plugin::Simple to call phases.

=method my @a=$self->filter_phases (sub {/^b/});

return only those phases which match the criterion.

=cut

has 'phases' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {'filter_phases' => 'grep'},
);


=attr plugins

the accessor 'plugins' returns a hashRef with all registered
plugins in their respective phases:
  my $registry=$plugins->plugins;
  
  #returns first plugin from that phase
  $registry->{$phase}[0]; 

You can't use 'plugins' in the constructor. User register instead to get 
plugins in this list after construction.

=cut

has 'plugins' => (
    is       => 'ro',
    isa      => 'HashRef[ArrayRef[Str]',
    init_arg => undef,
);

=method my @registered_plugins=$self->plugin_list

List all registered plugins. Returns a list.

=cut

sub list_plugins {
    my $self     = shift;
    my $registry = $self->plugins;
    my @p;
    foreach my $phase (keys %{$registry}) {
        foreach my $plugin (@{$registry->{$phase}}) {
            push(@p, $plugin);
        }
    }
    return @p;
}

=method my @plugins=filter_plugins(sub {/Test/}); 

return registered plutings whose names fits the filter criterion
=cut

sub filter_plugins {
    my ($self, $filter) = @_;
    return if (!$filter);
    return grep ($filter, $self->list_plugins);
}


=method my ($obj,$ret)=return_value($plugin)

Expects the plugin (label), returns the plugin object and return value from 
execute as list.

=cut

sub return_value {
    my $self = shift;
    my $plugin = shift || return;

    #not sure confess is the right thing to do here
    if (!$self->filter_plugins(sub {/^$plugin$/})) {
        confess "plugin '$plugin' not registered";
    }

    if (!defined $self->{return_values}{$plugin}) {
        confess "Return value for plugin '$plugin' doesn't exist!";
    }

    my $aref = $self->{return_values}{$plugin};
    return $aref->[0], $aref->[1];
}

=method $plugins->register ($plugin, $options)

Dies (confesses) on failure. 

Should we implement an option for lazy load? Then load would be delayed until 
when we need execute. Not now, but maybe later. 

Should return name of plugin on success.

=cut

sub register {
    my ($self, $plugin, $options) = @_;
    $options = {} if (!$options);

    load_class($plugin, $options);

    if (!$plugin->does('Plugin::Simple::Role::Plugin')) {
        confess
          "Your plugin '$plugin' doesn't plug in right (Plugin::Simple::Role::Plugin).";
    }

    my $phase = $plugin->phase();
    $self->_phase_exists($phase);

    #print "plugin $plugin comes with phase $phase\n";

    push @{$self->{plugins}{$phase}}, $plugin;
    return $plugin;    #success
}

=method my @p=$self->execute($phase,$core);

returns list of plugins which were run. Accepts whatever you pass it. It 
doesn't have to be your core.

=cut

sub execute {
    my $self  = shift;
    my $phase = shift;

    $self->_phase_exists($phase);
    my $aref = $self->{plugins}{$phase};

    if (@{$aref} == 0) {
        confess "No plugins registered for phase '$phase'";
    }

    foreach my $plugin (@{$aref}) {
        my $obj = $plugin->new(@_);
        $self->{return_values}{$plugin} = [$obj, $obj->execute()];
    }
    return $aref;
}

sub _phase_exists {
    my ($self, $phase) = @_;
    if (!$self->filter_phases(sub {/^$phase$/})) {
        confess "Phase '$phase' unknown";
    }
}

1;

=head1 DESCRIPTION

=head2 Non-essential bla bla bla

It's so easy to implement plugins in perl that you don't need a separate 
module. However, perhaps you like it a little easier. 

I think that a plugin system is just a mechanism which allows you to load 
plugins (code) from your configuration (i.e. without changing the code of your 
core). Plugins make your code modular, extendable, or in a word: cool. 

There are many easy ways to implement plugins in perl. I am trying to learn 
from Dancer and Dist::Zilla, two projects with plugins that I came across in 
the past. Let me know if you think there are other plugin systems which I 
should look at. 

This is my first attempt at coming up with a plugin system.

=head2 Features of Plugin Systems

=over

=item useing / loading

A plugin system has to have way loading your code. For example, with 
perl's use, require or Class::Load, as a base or role, or implementing a role.

=item starting point

A plugin system has to have somewhere to start. I assume this is always a sub
which gets called from the core when the time has come. 

=item phases

Many plugin systems have phases during which they call plugins, so that plugins
don't all get run at one time and in arbitrary order, but at different times
in your app and when you want them. Let's say sufficiently real-wordly plugin
systems need this feature.

=item access

Plugin system allow the plugin a varying amount of access to the core program. 
This being perl with little real closure for objects, I typically just hand all 
of core to the plugin, but a good plugin system might have good reason to be 
more restrictive.

=head1 SEE ALSO

L<MST's blog|
http://shadow.cat/blog/matt-s-trout/beautiful-perl-a-simple-plugin-system/>

