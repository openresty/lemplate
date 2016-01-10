# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

run_tests;

__DATA__

=== TEST 1: simple varaible interpolation
--- tt2
Hello, [% world %]!
--- define: world = "Lua"
--- out
Hello, Lua!
