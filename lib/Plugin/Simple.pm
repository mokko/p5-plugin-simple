#ABSTRACT: Simply make your app pluggable
package Plugin::Simple;
use strict;
use warnings;
use Moose;
use Carp 'confess';
use Class::Load qw(load_class);
#use Data::Dumper;

=head1 SYNOPSIS

  package YourPlugin;
  use Moose;                           
  with 'Plugin::Simple::Role::Plugin'; 

  has 'input' => (is=>'ro', isa=>'Int');

  sub phase {'foo'}
  
  sub BUILD {
      my ($self)=@_; #receive what you hand over in execute below
      $self->input; #access stuff passed down from core;
      #...
      $self->return ($something); #available in core when plugin is done
  }

  package YourApp;
  use Plugin::Simple;

  #during configuration 
  $ps=Plugin::Simple->new(phases=>['foo', 'bar']); 

  #registers p under its phase & load/use it; $options from Load::Class 
  $ps->register ('YourPlugin',\%options);   

  #later during a phase: execute all plugins in this phase
  @p=$ps->execute (phase=>$phase, core=>$core); 

  foreach my $plugin (@p){
    my $return=$plugins->return_value($plugin);
  }

=attr  $aref=$ps->phases; 

Getter returns arrayRef with all phase labels. 

Note that order of phases has no impact on when they're called. It's up the app 
which makes use of Plugin::Simple (the core) to call the phases when they are
needed. 

Plugin::Simple->new (phases=>[qw(a,b,b)]) removes duplicate phases now.

=cut

has 'phases' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    trigger => \&_uniq_phases,
);

sub _uniq_phases {
    my ($self, $phases_aref)=@_;
    my %seen = ();
    my @unique = grep { ! $seen{ $_ }++ } @{$phases_aref};
    $self->{phases}=\@unique;
}

#
# METHODS
#

=method my $href=$ps->registry;

returns a hashRef with all registered plugins in their respective 
phases:
  my $registry=$ps->registry;
  
  #returns first plugin from that phase
  $registry->{$phase}[0]; 

You can't use 'registry' in the constructor. Use register instead to get 
plugins into the registry.

=cut

has 'registry' => (
    is       => 'ro',
    isa      => 'HashRef[ArrayRef[Str]',
    init_arg => undef,
);

=method my @plugins=$ps->filter_phases('Test');  

return only those registered plugins whose names fit the filter criterion.
Currently, only exact matches no regular expressions. Might change.

=cut

sub filter_phases {
    my $self = shift;
    my $filter = shift or return;
    return grep ($_ eq $filter, @{$self->{phases}});
}

=method my @a=$ps->add_phase ('phase1');

Teach the plugin system a new phase. You can add multiple phases at once:
  my @a=$self->add_phase ('phase1', 'phase2');

=cut

sub add_phase {
    my $self = shift;
    return if (!@_);
    foreach my $new_phase (@_) {

        #don't allow to same phase twice with add_phase
        if (!grep ($_ eq $new_phase, @{$self->{phases}})) {
            push @{$self->{phases}}, $new_phase;
        }
    }
    return @_;
}


=method my @registered_plugins=$ps->plugin_list

List all registered plugins as a list. (It flattens registry to a list.)

=cut

sub list_plugins {
    my $self = shift;
    my @p;
    foreach my $phase (keys %{$self->registry}) {
        foreach my $plugin (@{$self->registry->{$phase}}) {
            push(@p, $plugin);
        }
    }
    return @p;
}

=method my @plugins=$ps->filter_plugins(/Test/); #no sub! 

return only those registered plugins whose names fit the filter criterion.

=cut

sub filter_plugins {
    my $self = shift;
    my $filter = shift or return;
    return grep ($_ eq $filter, $self->list_plugins);
}


=method my $ret=$ps->return_value($plugin)

Expects the plugin (label), returns the return value from that plugin. If there
is no return value it returns undef.

You better make sure that you executed the plugin, because this method doesn't
do that for you.

=cut

sub return_value {
    my $self = shift;
    my $plugin = shift || return;

    #not sure confess is the right thing to do here
    if (!$self->filter_plugins($plugin)) {
        confess "plugin '$plugin' not registered";
    }

    if (!defined $self->{return_values}{$plugin}) {
        return undef;
    }

    return $self->{return_values}{$plugin};
}

=method $ps->register ($plugin, $options)

Dies (confesses) on failure. 

Should we implement an option for lazy load? Then load would be delayed until 
when we need execute. Not now, but maybe later. 

Returns name of plugin on success.

=cut

sub register {
    my ($self, $plugin, $options) = @_;
    $options = {} if (!$options);

    load_class($plugin, $options);

    if (!$plugin->does('Plugin::Simple::Role::Plugin')) {
        confess
          "Your plugin '$plugin' doesn't plug in right (Plugin::Simple::Role::Plugin).";
    }

    #phase could be malformed
    my $phase = $plugin->phase();
    confess 'Problem with phase' if (!$phase);
    $self->_phase_exists($phase);

    #prevent same plugin to register twice
    #print "plugin $plugin comes with phase $phase\n";
    if (!grep ($_ eq $plugin, @{$self->{registry}{$phase}})) {
        push @{$self->{registry}{$phase}}, $plugin;
    }
    return $plugin;    #success
}

=method my @p = $ps->execute(phase => $phase);

Makes new plugins for all plugins registered in this phase. Needs phase. 
Optionally accepts arguments for new. Hash elements other than 'phase' are 
passed to new verbatim. Returns list of plugins that were run. Use 
C<return_value> to access return value from that plugin.

=cut

sub execute {
    my $self  = shift;
    my %arg   = @_ or confess "Need some args";
    my $phase = delete $arg{phase} or confess "Need phase";

    $self->_phase_exists($phase);
    my $registered_plugins = $self->{registry}{$phase};

    if (@{$registered_plugins} == 0) {
        confess "No plugins registered for phase '$phase'";
    }

    #do I really need an execute in every plugin? It would be much
    #easier without it... execute gives me a proper return value
    #new also returns something, of course. The alternative would be to
    #hand over the result inside the object. I guess that would be
    #a requirement I could make: a la $self->return
    foreach my $plugin (@{$registered_plugins}) {
        my $p = $plugin->new(%arg);
        if ($p->return) {
            $self->{return_values}{$plugin} = $p->return;
        }
    }
    return @{$registered_plugins};
}

#
# PRIVATE
#

#make public? no need
sub _phase_exists {
    my ($self, $phase) = @_;
    if (!$self->filter_phases($phase)) {
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
core). Plugins make your code modular, extendable, and cool. 

There are many easy ways to implement plugins in perl. I am trying to learn 
from Dancer and Dist::Zilla, two projects with plugins that I came across in 
the past. Let me know if you think there are other plugin systems which I 
should look at. 

I call the main app which calls the plugins 'core'.

=head2 Features of Plugin Systems

=over

=item useing / loading

A plugin system has to have way to load plugins. For example, with perl's use,
require or modules like Class::Load. It can just use them, load them a base or
as a role, trait etc.

=item starting point

A plugin system has to have somewhere to start. I assume this is always a sub
which gets called from the core when the time has come. 

=item phases

Many plugin systems have phases during which they call plugins, so that plugins
don't all get run at one time and in arbitrary order, but at different times
in your app and when you want them. Let's say a sufficiently real-wordly plugin
systems need this feature.

Phases also allow the plugin-system to be plugin-unaware during compile (use) 
time. We know the phases during use time, but yet which plugins will be loaded
from config, so we execute every plugin registered for that particular phase
when the time for this phase has come.

=item access

Plugin systems allow the plugin a varying amount of access to the core program. 
This being perl with little real closure for objects, I typically just hand all 
of core to the plugin, but a good plugin system might have good reason to be 
more restrictive. Plugin::Simple allows you to choose what you hand down.

=head1 SEE ALSO

L<MST's blog|
http://shadow.cat/blog/matt-s-trout/beautiful-perl-a-simple-plugin-system/>

