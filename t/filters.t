# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

$ENV{LEMPLATE_POST_CHOMP} = 1;

run_tests;

__DATA__

=== TEST 1: html filter for >
--- tt2
[% "42 > 41" | html %] !!!
--- out
42 &gt; 41 !!!



=== TEST 2: html filter for &
--- tt2
[% "Jack & Jill" | html %] !!!
--- out
Jack &amp; Jill !!!



=== TEST 3: custom filter (with no args)
--- tt2
[% "Jack & Jill" | upper %] !!!
--- out
JACK & JILL !!!
--- init
require("%LUAMOD%").filters['upper'] = function(s)
    return string.upper(s)
end



=== TEST 4: custom filter (with args)
--- tt2
[% "Jack & Jill" | quote('"') %] !!!
--- out
"Jack & Jill" !!!
--- init
require("%LUAMOD%").filters['quote'] = function(s, a)
    return a[1] .. s .. a[1]
end
