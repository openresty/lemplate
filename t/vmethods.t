# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

$ENV{LEMPLATE_POST_CHOMP} = 1;

run_tests;

__DATA__

=== TEST 1: first
--- tt2
[% array = [ 'Jack' ] %]
[% array.first() %]
--- out chomp
Jack



=== TEST 2: join (no delimiter)
--- tt2
[% array = [ 'Jack', 'Jill' ] %]
[% array.join() %]
--- out chomp
Jack Jill



=== TEST 3: join (with delimiter)
--- tt2
[% array = [ 'Jack', 'Jill' ] %]
[% array.join('-') %]
--- out chomp
Jack-Jill



=== TEST 4: push
--- tt2
[% array = [ 'Jack', 'Jill' ]; array.push('Jump') %]
[% array.join('-') %]
--- out chomp
Jack-Jill-Jump



=== TEST 5: keys
--- tt2
[% hash = { 'Jack' => 41, 'Jill' => 42 }; hash.keys.join('-') %]
--- out chomp
Jack-Jill



=== TEST 6: split (no delimiter)
--- tt2
[% str = "Jack Jill"; str.split.join('-') %]
--- out chomp
Jack-Jill



=== TEST 7: split (with delimiter)
--- tt2
[% str = "Jack+Jill"; str.split('+').join('-') %]
--- out chomp
Jack-Jill



=== TEST 8: sort
--- tt2
[% array = [ 'Jill', 'Jack' ]; array.sort().join('-') %]
--- out chomp
Jack-Jill



=== TEST 9: size
--- tt2
[% array = [ 'Jack', 'Jill' ]; array.size %]
--- out chomp
2



=== TEST 10: push multiple
--- tt2
[% array = [ 'Jack', 'Jill' ]; array.push('Jump', "Foo") %]
[% array.join('-') %]
--- out chomp
Jack-Jill-Jump-Foo
