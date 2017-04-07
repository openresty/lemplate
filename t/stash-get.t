# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

$ENV{LEMPLATE_POST_CHOMP} = 1;

run_tests;

__DATA__

=== TEST 1: plain scalar
--- tt2
[% var = 'Jack'; var %]
--- out chomp
Jack



=== TEST 2: scalar number
--- tt2
[% var = 42; var %]
--- out chomp
42



=== TEST 3: array element
--- tt2
[% array = [ 'Jack', 'Jill' ]; array.1 %]
--- out chomp
Jill



=== TEST 4: hash element
--- tt2
[% hash = { 'Jack' => 41, 'Jill' => 42 }; hash.Jill %]
--- out chomp
42



=== TEST 5: array element
--- tt2
[% array = [ 'Jack', 'Jill' ]; index = 1; array.$index %]
--- out chomp
Jill



=== TEST 6: function variable
--- tt2
[% func %]
--- define
func = function () return "Jillian" end,
--- out chomp
Jillian



=== TEST 7: function variable with args
--- tt2
[% period("Jillian") %]
--- define
period = function (str) return str .. "." end,
--- out chomp
Jillian.



=== TEST 8: function returns array
--- tt2
[% array.2 %]
--- define
array = function () return {40, 41, 42} end,
--- out chomp
42



=== TEST 9: chaining keys
--- tt2
[% string.split().push(jump.uppercase).join('+') %]
[%# jump.uppercase %]
--- init
require("%LUAMOD%").vmethods['uppercase'] = function (s)
    return string.upper(s)
end
--- define
string = function () return "Jack Jill" end,
jump = function () return "jump" end,
--- out chomp
Jack+Jill+JUMP
