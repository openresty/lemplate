package t::TestLemplate;

use lib 'inc';
use Test::Base -Base;
use File::Temp qw( tempfile );
use File::Copy qw( copy );
use IPC::Run3 qw( run3 );
use Lemplate;

our @EXPORT = qw( run_tests );

sub run_tests {
    for my $block (blocks()) {
        run_test($block);
    }
}

sub run_test ($) {
    my $block = shift;
    #print $json_xs->pretty->encode(\@new_rows);
    #my $res = #print $json_xs->pretty->encode($res);
    my $name = $block->name;

    my $tt2 = $block->tt2;
    if (!defined $tt2) {
        die "No --- tt2 specified for test $name\n";
    }

    my ($out_fh, $tt2file) = tempfile("tmpXXXXX", SUFFIX => '.tt2', UNLINK => 1);
    print $out_fh $tt2;
    close $out_fh;

    my @cmd = ($^X, "./bin/lemplate", "--compile", $tt2file);

    my ($comp_out, $comp_err);

    run3(\@cmd, undef, \$comp_out, \$comp_err);

    #warn "res:$res\nerr:$comp_err\n";

    if (defined $block->comp_err) {
        if (ref $block->comp_err) {
            like $comp_err, $block->comp_err, "$name - comp_err expected";
        } else {
            is $comp_err, $block->comp_err, "$name - comp_err expected";
        }

    } elsif ($?) {
        if (defined $block->fatal) {
            pass("failed as expected");

        } else {
            fail("failed to compile TT2 source for test $name: $comp_err\n");
            return;
        }

    } else {
        if ($comp_err) {
            if (!defined $block->comp_err) {
                warn "$comp_err\n";

            } else {
                is $comp_err, $block->comp_err, "$name - err ok";
            }
        }
    }

    my $expected_lua = $block->lua;
    if (defined $expected_lua) {
        if (ref $expected_lua) {
            like $comp_out, $expected_lua, "$name - lua expected";
        } else {
            is $comp_out, $expected_lua, "$name - lua expected";
        }
    }

    my $luafile;
    ($out_fh, $luafile) = tempfile("tmpXXXXX", SUFFIX => '.lua', UNLINK => 1);
    print $out_fh $comp_out;
    close $out_fh;

    copy($luafile, "a.lua") or die $!;

    (my $luamod = $luafile) =~ s/\.lua$//;

    my $define = $block->define // '';
    my $init = $block->init // '';

    @cmd = ("resty", "-e", qq{$init ngx.print(require("$luamod").process("$tt2file", {$define}))});
    #warn "cmd: @cmd";

    my ($run_out, $run_err);

    run3(\@cmd, undef, \$run_out, \$run_err);

    if (defined $block->lua_err) {
        $run_err =~ s/^\S+\.lua:\d+:\s*//;
        if (ref $block->lua_err) {
            like $run_err, $block->lua_err, "$name - run_err expected";
        } else {
            is $run_err, $block->lua_err, "$name - run_err expected";
        }

    } elsif ($?) {
        if (defined $block->fatal) {
            pass("failed as expected");

        } else {
            fail("failed to run Lua code for test $name: $run_err\n");
            return;
        }

    } else {
        if ($run_err) {
            if (!defined $block->lua_err) {
                warn "$run_err\n";

            } else {
                is $run_err, $block->lua_err, "$name - err ok";
            }
        }
    }

    my $expected_out = $block->out;
    if (defined $expected_out) {
        if (defined $run_out) {
            $run_out =~ s/^\n+//gs;
            $run_out =~ s/\n\n+$/\n/gs;
        }
        if (ref $expected_out) {
            like $run_out, $expected_out, "$name - out expected";
        } else {
            is $run_out, $expected_out, "$name - out expected";
        }
    }
}

1;
