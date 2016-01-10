# vim:set ft= ts=4 sw=4 et fdm=marker:

use t::TestLemplate;

plan tests => 1 * blocks();

$ENV{LEMPLATE_POST_CHOMP} = 1;

run_tests;

__DATA__

=== TEST 1:
--- tt2
maybe
[% IF yes %]
yes
[% END %]

--- define: yes = 1
--- out
maybe
yes



=== TEST 2:
--- tt2
[% IF yes %]
yes
[% ELSE %]
no 
[% END %]

--- define: yes = 1
--- out
yes



=== TEST 3:
--- tt2
[% IF yes %]
yes
[% ELSE %]
no 
[% END %]

--- define: yes = 1
--- out
yes



=== TEST 4:
--- tt2
[% IF yes and true %]
yes
[% ELSE %]
no 
[% END %]

--- define: yes = 1, ['true'] = 'this is true'
--- out
yes



=== TEST 5:
--- tt2
[% IF yes && true %]
yes
[% ELSE %]
no 
[% END %]

--- define: yes = 1, ['true'] = 'this is true'
--- out
yes



=== TEST 6:
--- tt2
[% IF yes && sad || happy %]
yes
[% ELSE %]
no 
[% END %]

--- define: yes = 1, sad = '', happy = 'yes'
--- out
yes



=== TEST 7:
--- tt2
[% IF yes AND ten && true and twenty && 30 %]
yes
[% ELSE %]
no
[% END %]

--- define: yes = 1, ten = 10, ['true'] = 'this is true', twenty = 20
--- out
yes



=== TEST 8:
--- tt2
[% IF ! yes %]
no
[% ELSE %]
yes
[% END %]

--- define: yes = 1
--- out
yes



=== TEST 9:
--- tt2
[% UNLESS yes %]
no
[% ELSE %]
yes
[% END %]

--- define: yes = 1
--- out
yes



=== TEST 10:
--- tt2
[% "yes" UNLESS no %]

--- define: yes = 1, no = 0
--- out chomp
yes



=== TEST 11:
--- tt2
[% IF ! yes %]
no
[% ELSE %]
yes
[% END %]

--- define: yes = 1, no = 0
--- out
yes



=== TEST 12:
--- tt2
[% IF yes || no %]
yes
[% ELSE %]
no
[% END %]

--- define: yes = 1, no = 0
--- out
yes



=== TEST 13:
--- tt2
[% IF yes || no || true || false %]
yes
[% ELSE %]
no
[% END %]

--- define: yes = 1, no = 0, ['true'] = 'this is true', ['false'] = '0'
--- out
yes



=== TEST 14:
--- tt2
[% IF yes or no %]
yes
[% ELSE %]
no
[% END %]

--- define: yes = 1, no = 0
--- out
yes



=== TEST 15:
--- tt2
[% IF not false and not sad %]
yes
[% ELSE %]
no
[% END %]

--- define: ['false'] = '0', sad = ''
--- out
yes



=== TEST 16:
--- tt2
[% IF ten == 10 %]
yes
[% ELSE %]
no
[% END %]

--- define: ten = 10
--- out
yes



=== TEST 17:
--- tt2
[% IF ten == twenty %]
I canna break the laws of mathematics, Captain.
[% ELSIF ten > twenty %]
Your numerical system is inverted.  Please reboot your Universe.
[% ELSIF twenty < ten %]
Your inverted system is numerical.  Please universe your reboot.
[% ELSE %]
Normality is restored.  Anything you can't cope with is your own problem.
[% END %]

--- define: ten = 10, twenty = 20
--- out
Normality is restored.  Anything you can't cope with is your own problem.



=== TEST 18:
--- tt2
[% IF ten >= twenty or false %]
no
[% ELSIF twenty <= ten  %]
nope
[% END %]
nothing

--- define: ten = 10, twenty = 20, ['false'] = '0'
--- out
nothing



=== TEST 19:
--- tt2
[% IF ten >= twenty or false %]
no
[% ELSIF twenty <= ten  %]
nope
[% END %]
nothing

--- define: ten = 10, twenty = 20, ['false'] = '0'
--- out
nothing



=== TEST 20:
--- tt2
[% IF ten > twenty %]
no
[% ELSIF ten < twenty  %]
yep
[% END %]

--- define: ten = 10, twenty = 20, ['false'] = '0'
--- out
yep



=== TEST 21:
--- tt2
[% IF ten != 10 %]
no
[% ELSIF ten == 10  %]
yep
[% END %]

--- define: ten = 10
--- out
yep



=== TEST 22:
--- tt2
[% IF alpha AND omega %]
alpha and omega are true
[% ELSE %]
alpha and/or omega are not true
[% END %]
count: [% count %]

--- init
local counter = 0
--- define
alpha = function () counter = counter + 1 return counter end,
omega = function () counter = counter + 10 return 0 end,
count = function () return counter end,
reset = function () return counter == 0 end
--- out chomp
alpha and/or omega are not true
count: 11



=== TEST 23:
--- tt2
[% IF omega AND alpha %]
omega and alpha are true
[% ELSE %]
omega and/or alpha are not true
[% END %]
count: [% count %]

--- init: local counter = 11
--- define
['true'] = 'this is true',
alpha = function () counter = counter + 1 return counter end,
omega = function () counter = counter + 10 return 0 end,
count = function () return counter end,
reset = function () return counter == 0 end

--- out chomp
omega and/or alpha are not true
count: 21



=== TEST 24:
--- tt2
[% IF alpha OR omega %]
alpha and/or omega are true
[% ELSE %]
neither alpha nor omega are true
[% END %]
count: [% count %]

--- init: local counter = 21
--- define
['true'] = 'this is true',
alpha = function () counter = counter + 1 return counter end,
omega = function () counter = counter + 10 return 0 end,
count = function () return counter end,
reset = function () return counter == 0 end

--- out chomp
alpha and/or omega are true
count: 22



=== TEST 25:
--- tt2
[% IF omega OR alpha %]
alpha and/or omega are true
[% ELSE %]
neither alpha nor omega are true
[% END %]
count: [% count %]

--- init: local counter = 22
--- define
alpha = function () counter = counter + 1 return counter end,
omega = function () counter = counter + 10 return 0 end,
count = function () return counter end,
--- out chomp
alpha and/or omega are true
count: 33



=== TEST 26:
--- tt2
[% small = 5
   mid   = 7
   big   = 10
   both  = small + big
   less  = big - mid
   half  = big / small
   left  = big % mid
   mult  = big * small
%]
both: [% both +%]
less: [% less +%]
half: [% half +%]
left: [% left +%]
mult: [% mult +%]
maxi: [% mult + 2 * 2 +%]
mega: [% mult * 2 + 2 * 3 %]

--- out chomp
both: 15
less: 3
half: 2
left: 3
mult: 50
maxi: 54
mega: 106

