# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

$ENV{LEMPLATE_POST_CHOMP} = 1;

run_tests;

__DATA__

=== TEST 1: line 1
--- tt2
[% items = [ 'foo' 'bar' 'baz' 'qux' ] %]
[% FOREACH i = items %]
   * [% i +%]
[% END %]

--- out
   * foo
   * bar
   * baz
   * qux



=== TEST 2: line 99
--- tt2
[% items = [ 'foo' 'bar' 'baz' 'qux' ] %]
[% FOREACH i = items %]
   #[% loop.index %]/[% loop.max %] [% i +%]
[% END %]

--- out
   #0/3 foo
   #1/3 bar
   #2/3 baz
   #3/3 qux



=== TEST 3: line 110
--- tt2
[% items = [ 'foo' 'bar' 'baz' 'qux' ] %]
[% FOREACH i = items %]
   #[% loop.count %]/[% loop.size %] [% i +%]
[% END %]

--- out
   #1/4 foo
   #2/4 bar
   #3/4 baz
   #4/4 qux



=== TEST 4: line 121
--- SKIP
--- tt2
[% items = [ 'foo' 'bar' 'baz' 'qux' ] %]
[% FOREACH i = items %]
   #[% loop.number %]/[% loop.size %] [% i +%]
[% END %]

--- out
   #1/4 foo
   #2/4 bar
   #3/4 baz
   #4/4 qux



=== TEST 5: line 134
--- tt2
[% USE iterator(data) %]
[% FOREACH i = iterator %]
[% IF iterator.first %]
List of items:
[% END %]
   * [% i +%]
[% IF iterator.last %]
End of list
[% END %]
[% END %]

--- define
data = {'foo', 'bar', 'baz', 'qux', 'wiz', 'woz', 'waz'}
--- out
List of items:
   * foo
   * bar
   * baz
   * qux
   * wiz
   * woz
   * waz
End of list



=== TEST 6: line 157
--- tt2
[% FOREACH i = [ 'foo' 'bar' 'baz' 'qux' ] %]
[% "$loop.prev<-" IF loop.prev -%][[% i -%]][% "->$loop.next" IF loop.next +%]
[% END %]

--- out
[foo]->bar
foo<-[bar]->baz
bar<-[baz]->qux
baz<-[qux]

