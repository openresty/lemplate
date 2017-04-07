# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

$ENV{LEMPLATE_POST_CHOMP} = 1;

run_tests;

__DATA__

=== TEST 1: first
--- tt2
[% array = [ 'Jack' ] %]
[% array.first() %].
--- out
Jack.



=== TEST 2: join (no delimiter)
--- tt2
[% array = [ 'Jack', 'Jill' ] %]
[% array.join() %].
--- out
Jack Jill.



=== TEST 3: join (with delimiter)
--- tt2
[% array = [ 'Jack', 'Jill' ] %]
[% array.join('-') %].
--- out
Jack-Jill.



=== TEST 4: push
--- tt2
[% array = [ 'Jack', 'Jill' ] %]
[% array = array.push('Jump') %]
[% array.join() %].
--- out
Jack Jill Jump.
