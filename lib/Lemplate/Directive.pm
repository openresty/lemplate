package Lemplate::Directive;
use strict;
use warnings;

our $VERSION = '0.13';

our $OUTPUT = 'i = i + 1 output[i] =';
our $WHILE_MAX = 1000;

# parser state variable
# only true when inside JAVASCRIPT blocks
our $INJAVASCRIPT = 0;

sub new {
    my $class = shift;

    return bless {}, $class
}

sub template {
    my ($class, $block) = @_;

    return "function() return '' end" unless $block =~ /\S/;

    return <<"...";
function (context)
    if not context then
        return error("Lemplate function called without context\\n")
    end
    local stash = context.stash
    local output = {}
    local i = 0

$block

    return output
end
...
}

# Try to do 1 .. 10 expansions
sub _attempt_range_expand_val ($) {
    my $val = shift;
    return $val unless
        my ( $from, $to ) = $val =~ m/\s*\[\s*(\S+)\s*\.\.\s*(\S+)\s*\]/;

    die "Range expansion is current supported for positive/negative integer values only (e.g. [ 1 .. 10 ])\nCannot expand: $val" unless $from =~ m/^-?\d+$/ && $to =~ m/^-?\d+$/;

    return join '', '[', join( ',', $from .. $to ), ']';
}

#------------------------------------------------------------------------
# textblock($text)
#------------------------------------------------------------------------

sub textblock {
    my ($class, $text) = @_;
    return $text if $INJAVASCRIPT;
    return "$OUTPUT " . $class->text($text);
}

#------------------------------------------------------------------------
# text($text)
#------------------------------------------------------------------------

sub text {
    my ($class, $text) = @_;
    for ($text) {
        s/([\'\\])/\\$1/g;
        s/\n/\\n/g;
        s/\r/\\r/g;
    }
    return "'" . $text . "'";
}

#------------------------------------------------------------------------
# ident(\@ident)                                             foo.bar(baz)
#------------------------------------------------------------------------

sub ident {
    my ($class, $ident) = @_;
    return "''" unless @$ident;
    my $ns;

    # does the first element of the identifier have a NAMESPACE
    # handler defined?
    if (ref $class && @$ident > 2 && ($ns = $class->{ NAMESPACE })) {
        my $key = $ident->[0];
        $key =~ s/^'(.+)'$/$1/s;
        if ($ns = $ns->{ $key }) {
            return $ns->ident($ident);
        }
    }

    if (scalar @$ident <= 2 && ! $ident->[1]) {
        $ident = $ident->[0];
    }
    else {
        $ident = '{' . join(', ', @$ident) . '}';
    }
    return "stash_get(stash, $ident)";
}


#------------------------------------------------------------------------
# assign(\@ident, $value, $default)                             foo = bar
#------------------------------------------------------------------------

sub assign {
    my ($class, $var, $val, $default) = @_;

    if (ref $var) {
        if (scalar @$var == 2 && ! $var->[1]) {
            $var = $var->[0];
        }
        else {
            $var = '{' . join(', ', @$var) . '}';
        }
    }
    $val =  _attempt_range_expand_val $val;
    $val .= ', 1' if $default;
    return "stash_set(stash, $var, $val)";
}


#------------------------------------------------------------------------
# args(\@args)                                        foo, bar, baz = qux
#------------------------------------------------------------------------

sub args {
    my ($class, $args) = @_;
    my $hash = shift @$args;
    push(@$args, '{ ' . join(', ', @$hash) . ' }')
        if @$hash;

    return '{}' unless @$args;
    return '{ ' . join(', ', @$args) . ' }';
}


#------------------------------------------------------------------------
# filenames(\@names)
#------------------------------------------------------------------------

sub filenames {
    my ($class, $names) = @_;
    if (@$names > 1) {
        $names = '[ ' . join(', ', @$names) . ' ]';
    }
    else {
        $names = shift @$names;
    }
    return $names;
}


#------------------------------------------------------------------------
# get($expr)                                                    [% foo %]
#------------------------------------------------------------------------

sub get {
    my ($class, $expr) = @_;
    return "$OUTPUT $expr";
}

sub block {
    my ($class, $block) = @_;
    return join "\n", map {
        s/^#(?=line \d+)/-- /gm;
        $_;
    } @{ $block || [] };
}

#------------------------------------------------------------------------
# call($expr)                                              [% CALL bar %]
#------------------------------------------------------------------------

sub call {
    my ($class, $expr) = @_;
    $expr .= ';';
    return $expr;
}


#------------------------------------------------------------------------
# set(\@setlist)                               [% foo = bar, baz = qux %]
#------------------------------------------------------------------------

sub set {
    my ($class, $setlist) = @_;
    my $output;
    while (my ($var, $val) = splice(@$setlist, 0, 2)) {
        $output .= $class->assign($var, $val) . ";\n";
    }
    chomp $output;
    return $output;
}


#------------------------------------------------------------------------
# default(\@setlist)                   [% DEFAULT foo = bar, baz = qux %]
#------------------------------------------------------------------------

sub default {
    my ($class, $setlist) = @_;
    my $output;
    while (my ($var, $val) = splice(@$setlist, 0, 2)) {
        $output .= &assign($class, $var, $val, 1) . ";\n";
    }
    chomp $output;
    return $output;
}


#------------------------------------------------------------------------
# include(\@nameargs)                    [% INCLUDE template foo = bar %]
#         # => [ [ $file, ... ], \@args ]
#------------------------------------------------------------------------

sub include {
    my ($class, $nameargs) = @_;
    my ($file, $args) = @$nameargs;
    my $hash = shift @$args;
    $file = $class->filenames($file);
    (my $raw_file = $file) =~ s/^'|'$//g;
    $Lemplate::ExtraTemplates{$raw_file} = 1;
    my $file2 = "'$Lemplate::TemplateName/$raw_file'";
    my $str_args = (@$hash ? ', { ' . join(', ', @$hash) . ' }' : '');
    return "$OUTPUT context.include(context, template_map['$Lemplate::TemplateName/$raw_file'] and $file2 or $file$str_args)";
}


#------------------------------------------------------------------------
# process(\@nameargs)                    [% PROCESS template foo = bar %]
#         # => [ [ $file, ... ], \@args ]
#------------------------------------------------------------------------

sub process {
    my ($class, $nameargs) = @_;
    my ($file, $args) = @$nameargs;
    my $hash = shift @$args;
    $file = $class->filenames($file);
    (my $raw_file = $file) =~ s/^'|'$//g;
    $Lemplate::ExtraTemplates{$raw_file} = 1;
    $file .= @$hash ? ', { ' . join(', ', @$hash) . ' }' : '';
    return "$OUTPUT context.process(context, $file)";
}


#------------------------------------------------------------------------
# if($expr, $block, $else)                             [% IF foo < bar %]
#                                                         ...
#                                                      [% ELSE %]
#                                                         ...
#                                                      [% END %]
#------------------------------------------------------------------------

sub if {
    my ($class, $expr, $block, $else) = @_;
    my @else = $else ? @$else : ();
    $else = pop @else;

    my $output = "if tt2_true($expr) then\n$block\n";

    foreach my $elsif (@else) {
        ($expr, $block) = @$elsif;
        $output .= "elseif tt2_true($expr) then\n$block\n";
    }
    if (defined $else) {
        $output .= "else\n$else\nend\n";
    } else {
        $output .= "end\n";
    }

    return $output;
}

#------------------------------------------------------------------------
# foreach($target, $list, $args, $block)    [% FOREACH x = [ foo bar ] %]
#                                              ...
#                                           [% END %]
#------------------------------------------------------------------------

sub foreach {
    my ($class, $target, $list, $args, $block) = @_;
    $args  = shift @$args;
    $args  = @$args ? ', { ' . join(', ', @$args) . ' }' : '';

    my ($loop_save, $loop_set, $loop_restore, $setiter);
    if ($target) {
        $loop_save =
            'local oldloop = ' . $class->ident(["'loop'"]);
        $loop_set = "stash['$target'] = value";
        $loop_restore = "stash_set(stash, 'loop', oldloop)";
    }
    else {
        die "XXX - Not supported yet";
        $loop_save = 'stash = context.localise()';
        $loop_set =
            "stash.get(['import', [value]]) if typeof(value) == 'object'";
        $loop_restore = 'stash = context.delocalise()';
    }

    $list = _attempt_range_expand_val $list;

    return <<EOF;

-- FOREACH
do
    local list = $list
    local iterator
    if list.list then
        iterator = list
        list = list.list
    end
    $loop_save
    local count
    if not iterator then
        count = table_maxn(list)
        iterator = { count = 1, max = count - 1, index = 0, size = count, first = true, last = false, prev = "" }
    else
        count = iterator.size
    end
    stash.loop = iterator
    for idx, value in ipairs(list) do
        if idx == count then
            iterator.last = true
        end
        iterator.index = idx - 1
        iterator.count = idx
        iterator.next = list[idx + 1]
        $loop_set
$block
        iterator.first = false
        iterator.prev = value
    end
    $loop_restore
end
EOF
}


#------------------------------------------------------------------------
# next()                                                       [% NEXT %]
#
# Next iteration of a FOREACH loop (experimental)
#------------------------------------------------------------------------

sub next {
  return <<EOF;
  return error("NEXT not implemented yet")
EOF
}

#------------------------------------------------------------------------
# wrapper(\@nameargs, $block)            [% WRAPPER template foo = bar %]
#          # => [ [$file,...], \@args ]
#------------------------------------------------------------------------
sub wrapper {
    my ($class, $nameargs, $block) = @_;
    my ($file, $args) = @$nameargs;
    my $hash = shift @$args;

    s/ => /: / for @$hash;
    return $class->multi_wrapper($file, $hash, $block)
        if @$file > 1;
    $file = shift @$file;
    push(@$hash, "'content': output");
    $file .= @$hash ? ', { ' . join(', ', @$hash) . ' }' : '';

    return <<EOF;

// WRAPPER
$OUTPUT (function() {
    var output = '';
$block;
    return context.include($file);
})();
EOF
}

sub multi_wrapper {
    my ($class, $file, $hash, $block) = @_;

    push(@$hash, "'content': output");
    $hash = @$hash ? ', { ' . join(', ', @$hash) . ' }' : '';

    $file = join(', ', reverse @$file);
#    print STDERR "multi wrapper: $file\n";

    return <<EOF;

// WRAPPER
$OUTPUT (function() {
    var output = '';
$block;
    var files = new Array($file);
    for (var i = 0; i < files.length; i++) {
        output = context.include(files[i]$hash);
    }
    return output;
})();
EOF
}


#------------------------------------------------------------------------
# while($expr, $block)                                 [% WHILE x < 10 %]
#                                                         ...
#                                                      [% END %]
#------------------------------------------------------------------------

sub while {
    my ($class, $expr, $block) = @_;

    return <<EOF;

-- WHILE
do
    local failsafe = $WHILE_MAX;
    while $expr do
        failsafe = failsafe - 1
        if failsafe <= 0 then
            break
        end
$block
    end
    if not failsafe then
        return error("WHILE loop terminated (> $WHILE_MAX iterations)\\n")
    end
end
EOF
}

#------------------------------------------------------------------------
# javascript($script)                                   [% JAVASCRIPT %]
#                                                           ...
#                                                       [% END %]
#------------------------------------------------------------------------
sub javascript {
    my ( $class, $javascript ) = @_;
    return $javascript;
}

sub no_javascript {
    my ( $class ) = @_;
    die "EVAL_JAVASCRIPT has not been enabled, cannot process [% JAVASCRIPT %] blocks";
}

#------------------------------------------------------------------------
# switch($expr, \@case)                                    [% SWITCH %]
#                                                          [% CASE foo %]
#                                                             ...
#                                                          [% END %]
#------------------------------------------------------------------------

sub switch {
    my ($class, $expr, $case) = @_;
    my @case = @$case;
    my ($match, $block, $default);
    my $caseblock = '';

    $default = pop @case;

    foreach $case (@case) {
        $match = $case->[0];
        $block = $case->[1];
#        $block = pad($block, 1) if $PRETTY;
        $caseblock .= <<EOF;
case $match:
$block
break;

EOF
    }

    if (defined $default) {
        $caseblock .= <<EOF;
default:
$default
break;
EOF
    }
#    $caseblock = pad($caseblock, 2) if $PRETTY;

return <<EOF;

    switch($expr) {
$caseblock
    }

EOF
}


#------------------------------------------------------------------------
# throw(\@nameargs)                           [% THROW foo "bar error" %]
#       # => [ [$type], \@args ]
#------------------------------------------------------------------------

sub throw {
    my ($class, $nameargs) = @_;
    my ($type, $args) = @$nameargs;
    my $hash = shift(@$args);
    my $info = shift(@$args);
    $type = shift @$type;

    return qq{return error({$type, $info})};
}


#------------------------------------------------------------------------
# clear()                                                     [% CLEAR %]
#
# NOTE: this is redundant, being hard-coded (for now) into Parser.yp
#------------------------------------------------------------------------

sub clear {
    return "output = {}";
}


#------------------------------------------------------------------------
# break()                                                     [% BREAK %]
#
# NOTE: this is redundant, being hard-coded (for now) into Parser.yp
#------------------------------------------------------------------------

sub break {
    return 'break';
}

#------------------------------------------------------------------------
# return()                                                   [% RETURN %]
#------------------------------------------------------------------------

sub return {
    return "return output"
}


#------------------------------------------------------------------------
# stop()                                                       [% STOP %]
#------------------------------------------------------------------------

sub stop {
    return "return error('Lemplate.STOP\\n' .. concat(output))";
}


#------------------------------------------------------------------------
# use(\@lnameargs)                         [% USE alias = plugin(args) %]
#     # => [ [$file, ...], \@args, $alias ]
#------------------------------------------------------------------------

sub use {
    my ($class, $lnameargs) = @_;
    my ($file, $args, $alias) = @$lnameargs;
    $file = shift @$file;       # same production rule as INCLUDE
    $alias ||= $file;
    $args = &args($class, $args);
    $file .= ", $args" if $args;
    return "-- USE\n"
         . "stash_set(stash, $alias, context.plugin(context, $file))";
}


#------------------------------------------------------------------------
# raw(\@lnameargs)                         [% RAW alias = plugin(args) %]
#     # => [ [$file, ...], \@args, $alias ]
#------------------------------------------------------------------------

sub raw {
    my ($class, $lnameargs) = @_;
    my ($file, $args, $alias) = @$lnameargs;
    $file = shift @$file;       # same production rule as INCLUDE
    $alias ||= $file;
    $args = &args($class, $args);
#    $file .= ", $args" if $args;
    $file =~ s/'|"//g;
    return "// RAW\n"
         . "stash_set(stash, $alias, $file)";
}


#------------------------------------------------------------------------
# stubs()                                                      [% STOP %]
#------------------------------------------------------------------------

sub filter {
    my ($class, $lnameargs, $block) = @_;
    my ($name, $args, $alias) = @$lnameargs;
    $name = shift @$name;
    $args = &args($class, $args);
    $args = $args ? "$args, $alias" : ", null, $alias"
        if $alias;
    $name .= ", $args" if $args;
    return <<EOF;

-- FILTER
local value
do
    local output = {}
    local i = 0

$block

    value = context.filter(output, $name)
end
$OUTPUT value
EOF
}

sub quoted {
    my $class = shift;
    if ( @_ && ref($_[0]) ) {
        return join( " .. ", @{$_[0]} );
    }
    return "return error('QUOTED called with unknown arguments in Lemplate')";
}

#------------------------------------------------------------------------
# macro($name, $block, \@args)
#------------------------------------------------------------------------

sub macro {
    my ($class, $ident, $block, $args) = @_;

    if ($args) {
        $args = join(';', map { "args['$_'] = fargs.shift()" } @$args);

        return <<EOF;

//MACRO
stash.set('$ident', function () {
    var output = '';
    var args = {};
    var fargs = Array.prototype.slice.call(arguments);
    $args;
    args.arguments = Array.prototype.slice.call(arguments);

    var params = fargs.shift() || {};

    for (var key in params) {
        args[key] = params[key];
    }

    context.stash.clone(args);
    try {
$block
    }
    catch(e) {
        var error = context.set_error(e, output);
        throw(error);
    }

    context.stash.declone();
    return output;
});

EOF

    }
    else {
        return <<EOF;

//MACRO

stash.set('$ident', function () {
    var output = '';
    var args = {};

    var fargs = Array.prototype.slice.call(arguments);
    args.arguments = Array.prototype.slice.call(arguments);

    if (typeof arguments[0] == 'object') args = arguments[0];

    context.stash.clone(args);
    try {
$block
    }
    catch(e) {
        var error = context.set_error(e, output);
        throw(error);
    }

    context.stash.declone();
    return output;});

EOF
    }
}

sub capture {
    my ($class, $name, $block) = @_;

    if (ref $name) {
        if (scalar @$name == 2 && ! $name->[1]) {
            $name = $name->[0];
        }
        else {
            $name = '[' . join(', ', @$name) . ']';
        }
    }

    return <<EOF;

// CAPTURE
(function() {
	var output = '';
	$block
	stash.set($name, output);
})();
EOF

}

BEGIN {
    return;  # Comment out this line to get callback traces
    no strict 'refs';
    my $pkg = __PACKAGE__ . '::';
    my $stash = \ %$pkg;
    use strict 'refs';
    for my $name (keys %$stash) {
        my $glob = $stash->{$name};
        if (*$glob{CODE}) {
            my $code = *$glob{CODE};
            no warnings 'redefine';
            $stash->{$name} = sub {
                warn "Calling $name(@_)\n";
                &$code(@_);
            };
        }
    }
}


1;

__END__

=encoding UTF-8

=head1 NAME

Lemplate::Directive - Lemplate Code Generating Backend

=head1 SYNOPSIS

    use Lemplate::Directive;

=head1 DESCRIPTION

Lemplate::Directive is the analog to Template::Directive, which is the
module that produces that actual code that templates turn into. The
Lemplate version obviously produces Lua code rather than Perl.
Other than that the two modules are almost exactly the same.

=head1 BUGS

Unfortunately, some of the code generation seems to happen before
Lemplate::Directive gets control. So it currently has heuristical code
to rejigger Perl code snippets into Lua. This processing needs to
happen upstream once I get more clarity on how Template::Toolkit works.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2016. Yichun Zhang (agentzh). All rights reserved.

Copyright (c) 2006-2014. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
