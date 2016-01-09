#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan qw/no_plan/;

use Lemplate;

is( scalar Lemplate::recurse_dir( 't/../t/assets/jt/a' ), 1, 'Only find one file, the rest should be hidden' );
