#!perl

use strict;
use warnings;
use Test::More;
use Plugin::Tiny;
use Try::Tiny;
use FindBin;
use File::Spec;
use Scalar::Util 'blessed';
use Data::Dumper;
use lib File::Spec->catfile('t', 'lib');

use_ok('Plugin::Tiny');

my $ps = Plugin::Tiny->new();
ok($ps, 'new');

ok( $ps->register(
        phase  => 'foo',                  #required
        plugin => 'TinyTestPlugin',    #required
        plugins=> $ps,
        bar    => 'tiny',
    ), 'simple register'
);

try {
    $ps->register(
        phase  => 'foo',                  #required
        plugin => 'TinyTestPlugin',    #required
        bar    => 'tiny',
    );
} 
finally {
    ok (@_, 'register fails without plugins')
};

my ($p1,$p2);
ok ($p1=$ps->get_plugin ('foo'), 'get p1');
is ($p1->do_something, 'doing something', 'execute return value');
ok ($p1->register_another_plugin, 'registering a new plug from inside a plug');
ok ($p2=$ps->get_plugin ('bar'), 'get p2');
is ($p2->do_something, 'a plugin that is loaded by another plugin', 'return looks good');
done_testing;
