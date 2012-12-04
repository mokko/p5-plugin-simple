#!perl

use strict;
use warnings;
use Test::More tests => 18;
use Try::Tiny;
use FindBin;
use File::Spec;
use Scalar::Util 'blessed';

#use lib File::Spec->catfile('t', 'lib');
use lib 't/lib';    #todo

#1
use_ok('Plugin::Simple', 'can load Plugin::Simple');

#2
note "new and plugins";
my $plugins = Plugin::Simple->new();
ok($plugins, 'new returns something');

#3 should I test if phase is unique? no...

$plugins = Plugin::Simple->new(phases => ['Phase1', 'Phase2']);
ok($plugins, 'constructor with phases');
my $ph = $plugins->phases;
ok($ph->[0] eq 'Phase1' && $ph->[1] eq 'Phase2', 'phases getter');


#7: positives
note "register";
ok($plugins->register('TestPlugin1'), 'register TestPlugin1');
ok($plugins->register('TestPlugin2'), 'register TestPlugin2');
is($plugins->register('TestPlugin1'), 'TestPlugin1', 'register return value');

#10: negatives
try { $plugins->register('TestPlugin3'); }
catch { ok($_, 'non existant phase') };

try { $plugins->register('NonExistantPlugin'); }
catch { ok($_, 'non existing plugin') };


note "execute";

#12: positives
ok($plugins->execute('Phase1'), 'execute Phase1');
ok($plugins->execute('Phase2', {foo => 'bar'}), 'execute Phase2');


#13: negatives
#todo excute and fail without foo bar
#ok($plugins->execute('Phase1', {foo=>'bar'}), 'execute Phase1');
try { $plugins->execute('non_existant_phase'); }
catch { ok($_, 'non existant phase') };

note "return_value";
{
    my ($obj, $ret) = $plugins->return_value('TestPlugin1');
    is(ref $obj, 'TestPlugin1', 'TestPlugin object ');
    is($ret,     'bar',         'TestPlugin return value');
}
{
    my ($obj, $ret) = $plugins->return_value('TestPlugin2');
    ok(!$ret, 'testing return value undef');
}
{
    try { $plugins->return_value('TestPlugin3'); }
    catch { ok($_, 'return_value on non-existing-plugin') };
}

note "list_plugins and filter_plugin";
{
my @p= $plugins->list_plugins;
is ($p[0], 'TestPlugin1', 'list_plugin');
}

{
my @p = $plugins->filter_plugins(sub {/TestPlugin1/});
is($p[0], 'TestPlugin1', 'filter_plugin');
}

