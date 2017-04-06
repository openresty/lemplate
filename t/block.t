# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

$ENV{LEMPLATE_POST_CHOMP} = 1;

run_tests;

__DATA__

=== TEST 1: line 1
--- tt2
[% BLOCK block1 %]
This is the original block1
[% END %]
[% INCLUDE block1 %]
[% INCLUDE blockdef %]
[% INCLUDE block1 %]

--- out
This is the original block1
start of blockdef
end of blockdef
This is the original block1
--- LAST



=== TEST 2: line 60
--- tt2
[% BLOCK block1 %]
This is the original block1
[% END %]
[% INCLUDE block1 %]
[% PROCESS blockdef %]
[% INCLUDE block1 %]

--- out
This is the original block1
start of blockdef
end of blockdef
This is block 1, defined in blockdef, a is alpha



=== TEST 3: line 74
--- tt2
[% INCLUDE block_a +%]
[% INCLUDE block_b %]

--- out
this is block a
this is block b



=== TEST 4: line 81
--- tt2
[% INCLUDE header
   title = 'A New Beginning'
+%]
A long time ago in a galaxy far, far away...
[% PROCESS footer %]

--- out
<html><head><title>A New Beginning</title></head><body>
A long time ago in a galaxy far, far away...
</body></html>



=== TEST 5: line 93
--- tt2
[% BLOCK foo:bar %]
blah
[% END %]
[% PROCESS foo:bar %]

--- out
blah



=== TEST 6: line 101
--- tt2
[% BLOCK 'hello html' -%]
Hello World!
[% END -%]
[% PROCESS 'hello html' %]

--- out
Hello World!

