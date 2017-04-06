# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

$ENV{LEMPLATE_POST_CHOMP} = 1;

run_tests;

__DATA__

=== TEST 1: html filter for >
--- tt2
[% "42 > 41" | html %]
--- out chomp
42 &gt; 41



=== TEST 2: html filter for &
--- tt2
[% "Jack & Jill" | html %]
--- out chomp
Jack &amp; Jill



=== TEST 3: lower
--- tt2
[% "Jack & Jill" | lower %]
--- out chomp
jack & jill



=== TEST 4: upper
--- tt2
[% "Jack & Jill" | upper %]
--- out chomp
JACK & JILL



=== TEST 5: custom filter (with no args)
--- tt2
[% "Jack & Jill" | period %]
--- out chomp
Jack & Jill.
--- init
require("%LUAMOD%").filters['period'] = function(s)
    return s .. '.'
end



=== TEST 6: custom filter (with args)
--- tt2
[% "Jack & Jill" | quote('"') %]
--- out chomp
"Jack & Jill"
--- init
require("%LUAMOD%").filters['quote'] = function(s, a)
    return a[1] .. s .. a[1]
end
