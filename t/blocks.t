# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

$ENV{LEMPLATE_POST_CHOMP} = 1;

run_tests;

__DATA__

=== TEST 1: line 1
--- tt2
[% INCLUDE blockdef/block1 %]

--- lua_err eval
qr{^file error - blockdef/block1: not found\n}
--- LAST



=== TEST 2: line 61
--- tt2
[% INCLUDE blockdef/block1 %]

--- out
This is block 1, defined in blockdef, a is alpha



=== TEST 3: line 68
--- tt2
[% INCLUDE blockdef/block1 a='amazing' %]

--- out
This is block 1, defined in blockdef, a is amazing



=== TEST 4: line 74
--- tt2
[% TRY; INCLUDE blockdef/none; CATCH; error; END %]

--- out
file error - blockdef/none: not found



=== TEST 5: line 79
--- tt2
[% INCLUDE "$dir/blockdef/block1" a='abstract' %]

--- out
This is block 1, defined in blockdef, a is abstract

