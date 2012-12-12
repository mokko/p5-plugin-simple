#!perl

use strict;
use warnings;
use Test::More tests => 24;
use Try::Tiny;
use FindBin;
use File::Spec;
use Scalar::Util 'blessed';
use Data::Dumper;
use lib File::Spec->catfile('t', 'lib');

#1
use_ok('Plugin::Simple', 'can load Plugin::Simple');

#2
note "new and phases";
my $plugin_system = Plugin::Simple->new();
ok($plugin_system, 'new without phases');

$plugin_system = Plugin::Simple->new(phases => ['Phase1', 'Phase2', 'Phase2']);
ok($plugin_system, 'new with phases');
my $phases_aref=$plugin_system->phases;
is ($phases_aref->[0], 'Phase1', 'phases getter');
ok (scalar (grep $_ eq 'Phase2', @{$phases_aref}) == 1, 'duplicates from new removed');
ok($plugin_system->filter_phases ('Phase1'), 'filter phases');

ok ($plugin_system->add_phase ('Phase3'), 'adding phase');
ok ($plugin_system->add_phase ('Phase3'), 'adding phase repeatedly');
ok($plugin_system->filter_phases ('Phase3'), 'add phase success');



#10: positives
note "register";
ok($plugin_system->register('TestPlugin1'), 'register TestPlugin1');
ok($plugin_system->register('TestPlugin2'), 'register TestPlugin2');
is($plugin_system->register('TestPlugin1'),
    'TestPlugin1', 'register return value');

#13: negatives
try { $plugin_system->register('TestPlugin3'); }
catch { ok($_, 'non existant phase') };

try { $plugin_system->register('NonExistantPlugin'); }
catch { ok($_, 'non existing plugin') };


#15: positives
note "execute";
ok($plugin_system->execute(phase => 'Phase1'), 'execute Phase1');
ok( $plugin_system->execute(
        phase => 'Phase2',
        foo   => 'bar'
    ),
    'execute Phase2'
);
ok( $plugin_system->execute(
        phase => 'Phase2',
        foo   => 'bar',
    ),
    'execute Phase2'
);

#18: negatives
try { $plugin_system->execute(phase => 'Phase2'); }
catch { ok($_, 'Phase2 without foo') } 
finally { die "need to die" if (!@_) };


try { $plugin_system->execute(phase => 'non_existant_phase'); }
catch { ok($_, 'non existant phase') }
finally { die "need to die" if (!@_) };

#20
note "return_value";
{
    my $ret = $plugin_system->return_value('TestPlugin1');
    is($ret, 'bar', 'TestPlugin return value correct');
}
{
    my $ret = $plugin_system->return_value('TestPlugin2');
    ok(!$ret, 'testing return value undef');
}
{
    try { $plugin_system->return_value('TestPlugin3'); }
    catch { ok($_, 'return_value on non-existing-plugin') }
    finally { die "need to die" if (!@_) };
}

#23
note "list_plugins and filter_plugin";
{
    my @p = $plugin_system->list_plugins;
    is($p[0], 'TestPlugin1', 'list_plugin');
}

{
    my @p = $plugin_system->filter_plugins('TestPlugin1');
    is($p[0], 'TestPlugin1', 'filter_plugin');
}
