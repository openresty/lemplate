#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "JavaScript::V8x::TestMoreish not available" unless eval { require JavaScript::V8x::TestMoreish };
}

plan qw/no_plan/;

use Lemplate;
use Lemplate::Runtime;

use JavaScript::V8x::TestMoreish;

my $jemplate = Lemplate->new;
my @js;

push @js, $jemplate->compile_template_content( <<_END_, 't0' );
[% BLOCK t1 %][% 3 DIV 2 %][% END %]
[% BLOCK t2 %][% 4 DIV 2 %][% END %]
[% BLOCK t3 %][% 5 DIV 2 %][% END %]
_END_

test_js_eval( Lemplate::Runtime->kernel );
test_js_eval( join "\n", @js, "1;" );
test_js <<'_END_';

areEqual( Lemplate.process( 't1' ), 1 );
areEqual( Lemplate.process( 't2' ), 2 );
areEqual( Lemplate.process( 't3' ), 2 );

_END_
