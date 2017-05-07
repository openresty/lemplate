# ToDo:
# - Use TT:Simple in Makefiles

# ABSTRACT: compiles Perl TT2 templates to standalone Lua modules for OpenResty

package Lemplate;

use strict;
use warnings;
use Template 2.14;
use Getopt::Long;

our $VERSION = '0.11';

use Lemplate::Parser;

#-------------------------------------------------------------------------------

our %ExtraTemplates;
our %ProcessedTemplates;
our $TemplateName;

sub usage {
    <<'...';
Usage:

    lemplate --runtime [runtime-opt]

    lemplate --compile [compile-opt] <template-list>

    lemplate --runtime [runtime-opt] --compile [compile-opt] <template-list>

    lemplate --list <template-list>

Where "--runtime" and "runtime-opt" can include:

    --runtime           Equivalent to --ajax=ilinsky --json=json2
    --runtime=standard

    --runtime=lite      Same as --ajax=none --json=none
    --runtime=jquery    Same as --ajax=jquery --json=none
    --runtime=yui       Same as --ajax=yui --json=yui
    --runtime=legacy    Same as --ajax=gregory --json=json2

    --json              By itself, equivalent to --json=json2
    --json=json2        Include http://www.json.org/json2.js for parsing/stringifying
    --json=yui          Use YUI: YAHOO.lang.JSON (requires external YUI)
    --json=none         Doesn't provide any JSON functionality except a warning

    --ajax              By itself, equivalent to --ajax=xhr
    --ajax=jquery       Use jQuery for Ajax get and post (requires external jQuery)
    --ajax=yui          Use YUI: yui/connection/connection.js (requires external YUI)
    --ajax=xhr          Use XMLHttpRequest (will automatically use --xhr=ilinsky if --xhr is not set)
    --ajax=none         Doesn't provide any Ajax functionality except a warning

    --xhr               By itself, equivalent to --xhr=ilinsky
    --xhr=ilinsky       Include http://code.google.com/p/xmlhttprequest/
    --xhr=gregory       Include http://www.scss.com.au/family/andrew/webdesign/xmlhttprequest/

    --xxx               Include XXX and JJJ helper functions

    --compact           Use the YUICompressor compacted version of the runtime

Where "compile-opt" can include:

    --include_path=DIR  Add directory to INCLUDE_PATH

    --start-tag
    --end-tag
    --pre-chomp
    --post-chomp
    --trim
    --any-case
    --eval
    --noeval
    -s, --source
    --exclude

For more information use:
    perldoc lemplate
...
}

sub main {
    my $class = shift;

    my @argv = @_;

    my ($template_options, $lemplate_options) = get_options(@argv);
    my ($runtime, $compile, $list) = @$lemplate_options{qw/runtime compile list/};

    if ($runtime) {
        print runtime_source_code(@$lemplate_options{qw/runtime ajax json xhr xxx compact/});
        return unless $compile;
    }

    my $templates = make_file_list($lemplate_options->{exclude}, @argv);
    print_usage_and_exit() unless @$templates;

    if ($list) {
        foreach (@$templates) {
            print STDOUT $_->{short} . "\n";
        }
        return;
    }

    if ($compile) {
        my $lemplate = Lemplate->new(%$template_options);
        print STDOUT $lemplate->_preamble;
        for (my $i = 0; $i < @$templates; $i++) {
            my $template = $templates->[$i];
            #warn "processing $template->{short}";
            my $content = slurp($template->{full});
            if ($content) {
                %ExtraTemplates = ();
                print STDOUT $lemplate->compile_template_content(
                    $content,
                    $template->{short}
                );
                my @new_files;
                for my $new_template (keys %ExtraTemplates) {
                    if (!$ProcessedTemplates{$new_template}) {
                        if (!-f $new_template) {
                            $new_template = "t/data/" . $new_template;
                        }
                        #warn $new_template;
                        if (-f $new_template) {
                            #warn "adding new template $new_template";
                            push @new_files, $new_template;
                        }
                    }
                }
                push @$templates, @{ make_file_list({}, @new_files) };
            }
        }
        print STDOUT "return _M\n";
        return;
    }

    print_usage_and_exit();
}

sub get_options {
    local @ARGV = @_;

    my $runtime;
    my $compile = 0;
    my $list = 0;

    my $start_tag = exists $ENV{LEMPLATE_START_TAG}
        ? $ENV{LEMPLATE_START_TAG}
        : undef;
    my $end_tag = exists $ENV{LEMPLATE_END_TAG}
        ? $ENV{LEMPLATE_END_TAG}
        : undef;
    my $pre_chomp = exists $ENV{LEMPLATE_PRE_CHOMP}
        ? $ENV{LEMPLATE_PRE_CHOMP}
        : undef;
    my $post_chomp = exists $ENV{LEMPLATE_POST_CHOMP}
        ? $ENV{LEMPLATE_POST_CHOMP}
        : undef;
    my $trim = exists $ENV{LEMPLATE_TRIM}
        ? $ENV{LEMPLATE_TRIM}
        : undef;
    my $anycase = exists $ENV{LEMPLATE_ANYCASE}
        ? $ENV{LEMPLATE_ANYCASE}
        : undef;
    my $eval_javascript = exists $ENV{LEMPLATE_EVAL_JAVASCRIPT}
        ? $ENV{LEMPLATE_EVAL_JAVASCRIPT}
        : 1;

    my $source  = 0;
    my $exclude = 0;
    my ($ajax, $json, $xxx, $xhr, $compact, $minify);

    my $help = 0;
    my @include_paths;

    GetOptions(
        "compile|c"     => \$compile,
        "list|l"        => \$list,
        "runtime|r:s"   => \$runtime,

        "start-tag=s"   => \$start_tag,
        "end-tag=s"     => \$end_tag,
        "trim=s"        => \$trim,
        "pre-chomp"     => \$pre_chomp,
        "post-chomp"    => \$post_chomp,
        "any-case"      => \$anycase,
        "eval!"         => \$eval_javascript,

        "source|s"      => \$source,
        "exclude=s"     => \$exclude,

        "ajax:s"        => \$ajax,
        "json:s"        => \$json,
        "xxx"           => \$xxx,
        "xhr:s"         => \$xhr,

        "include_path"  => \@include_paths,
        "compact"       => \$compact,
        "minify:s"      => \$minify,

        "help|?"        => \$help,
    ) or print_usage_and_exit();

    if ($help) {
        print_usage_and_exit();
    }

    ($runtime, $ajax, $json, $xxx, $xhr, $minify) = map { defined $_ && ! length $_ ? 1 : $_ } ($runtime, $ajax, $json, $xxx, $xhr, $minify);
    $runtime = "standard" if $runtime && $runtime eq 1;

    print_usage_and_exit("Don't understand '--runtime $runtime'") if defined $runtime && ! grep { $runtime =~ m/$_/ } qw/standard lite jquery yui legacy/;
    print_usage_and_exit("Can't specify --list with a --runtime and/or the --compile option") if $list && ($runtime || $compile);
    print_usage_and_exit() unless $list || $runtime || $compile;

    my $command =
        $runtime ? 'runtime' :
        $compile ? 'compile' :
        $list ? 'list' :
        print_usage_and_exit();

    my $options = {};
    $options->{START_TAG} = $start_tag if defined $start_tag;
    $options->{END_TAG} = $end_tag if defined $end_tag;
    $options->{PRE_CHOMP} = $pre_chomp if defined $pre_chomp;
    $options->{POST_CHOMP} = $post_chomp if defined $post_chomp;
    $options->{TRIM} = $trim if defined $trim;
    $options->{ANYCASE} = $anycase if defined $anycase;
    $options->{EVAL_JAVASCRIPT} = $eval_javascript if defined $eval_javascript;
    $options->{INCLUDE_PATH} = \@include_paths;

    return (
        $options,
        { compile => $compile, runtime => $runtime, list => $list,
            source => $source,
            exclude => $exclude,
            ajax => $ajax, json => $json, xxx => $xxx, xhr => $xhr,
            compact => $compact, minify => $minify },
    );
}


sub slurp {
    my $filepath = shift;
    open(F, '<', $filepath) or die "Can't open '$filepath' for input:\n$!";
    my $contents = do {local $/; <F>};
    close(F);
    return $contents;
}

sub recurse_dir {
    require File::Find::Rule;

    my $dir = shift;
    my @files;
    foreach ( File::Find::Rule->file->in( $dir ) ) {
        if ( m{/\.[^\.]+} ) {} # Skip ".hidden" files or directories
        else {
            push @files, $_;
        }
    }
    return @files;
}

sub make_file_list {
    my ($exclude, @args) = @_;

    my @list;

    foreach my $arg (@args) {
        unless (-e $arg) { next; } # file exists
        unless (-s $arg or -d $arg) { next; } # file size > 0 or directory (for Win platform)
        if ($exclude and $arg =~ m/$exclude/) { next; } # file matches exclude regex

        if (-d $arg) {
            foreach my $full ( recurse_dir($arg) ) {
                $full =~ /$arg(\/|)(.*)/;
                my $short = $2;
                push(@list, {full=>$full, short=>$short} );
            }
        }
        else {
            my $full = $arg;
            my $short = $full;
            $short =~ s/.*[\/\\]//;
            push(@list, {full=>$arg, short=>$short} );
        }
    }

    return [ sort { $a->{short} cmp $b->{short} } @list ];
}

sub print_usage_and_exit {
    print STDOUT join "\n", "", @_, "Aborting!", "\n" if @_;
    print STDOUT usage();
    exit;
}

sub runtime_source_code {
    die "generating a separate runtime not supported yet";
}

#-------------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub compile_module {
    my ($self, $module_path, $template_file_paths) = @_;
    my $result = $self->compile_template_files(@$template_file_paths)
      or return;
    open MODULE, "> $module_path"
        or die "Can't open '$module_path' for output:\n$!";
    print MODULE $result;
    close MODULE;
    return 1;
}

sub compile_module_cached {
    my ($self, $module_path, $template_file_paths) = @_;
    my $m = -M $module_path;
    return 0 unless grep { -M($_) < $m } @$template_file_paths;
    return $self->compile_module($module_path, $template_file_paths);
}

sub compile_template_files {
    my $self = shift;
    my $output = $self->_preamble;
    for my $filepath (@_) {
        my $filename = $filepath;
        $filename =~ s/.*[\/\\]//;
        open FILE, $filepath
          or die "Can't open '$filepath' for input:\n$!";
        my $template_input = do {local $/; <FILE>};
        close FILE;
        $output .=
            $self->compile_template_content($template_input, $filename);
    }
    return $output;
}

sub compile_template_content {
    die "Invalid arguments in call to Lemplate->compile_template_content"
      unless @_ == 3;
    my ($self, $template_content, $template_name) = @_;
    $TemplateName = $template_name;
    my $parser = Lemplate::Parser->new( ref($self) ? %$self : () );
    my $parse_tree = $parser->parse(
        $template_content, {name => $template_name}
    ) or die $parser->error;
    my $output =
        "-- $template_name\n" .
        "template_map['$template_name'] = " .
        $parse_tree->{BLOCK} .
        "\n";
    for my $function_name (sort keys %{$parse_tree->{DEFBLOCKS}}) {
        my $name = "$template_name/$function_name";
        next if $ProcessedTemplates{$name};
        #warn "seen $name";
        $ProcessedTemplates{$name} = 1;
        $output .=
            "template_map['$name'] = " .
            $parse_tree->{DEFBLOCKS}{$function_name} .
            "\n";
    }
    return $output;
}

sub _preamble {
    return <<'...';
--[[
   This Lua code was generated by Lemplate, the Lua
   Template Toolkit. Any changes made to this file will be lost the next
   time the templates are compiled.

   Copyright 2016 - Yichun Zhang (agentzh) - All rights reserved.

   Copyright 2006-2014 - Ingy döt Net - All rights reserved.
]]

local gsub = ngx.re.gsub
local concat = table.concat
local type = type
local math_floor = math.floor
local table_maxn = table.maxn

local _M = {
    version = '0.07'
}

local template_map = {}

local function tt2_true(v)
    return v and v ~= 0 and v ~= "" and v ~= '0'
end

local function tt2_not(v)
    return not v or v == 0 or v == "" or v == '0'
end

local context_meta = {}

function context_meta.plugin(context, name, args)
    if name == "iterator" then
        local list = args[1]
        local count = table_maxn(list)
        return { list = list, count = 1, max = count - 1, index = 0, size = count, first = true, last = false, prev = "" }
    else
        return error("unknown iterator: " .. name)
    end
end

function context_meta.process(context, file)
    local f = template_map[file]
    if not f then
        return error("file error - " .. file .. ": not found")
    end
    return f(context)
end

function context_meta.include(context, file)
    local f = template_map[file]
    if not f then
        return error("file error - " .. file .. ": not found")
    end
    return f(context)
end

context_meta = { __index = context_meta }

-- XXX debugging function:
-- local function xxx(data)
--     io.stderr:write("\n" .. require("cjson").encode(data) .. "\n")
-- end

local function stash_get(stash, expr)
    local result

    if type(expr) ~= "table" then
        result = stash[expr]
        if type(result) == "function" then
            return result()
        end
        return result or ''
    end

    result = stash
    for i = 1, #expr, 2 do
        local key = expr[i]
        if type(key) == "number" and key == math_floor(key) and key >= 0 then
            key = key + 1
        end
        local val = result[key]
        local args = expr[i + 1]
        if args == 0 then
            args = {}
        end

        if val == nil then
            if not _M.vmethods[key] then
                if type(expr[i + 1]) == "table" then
                    return error("virtual method " .. key .. " not supported")
                end
                return ''
            end
            val = _M.vmethods[key]
            args = {result, unpack(args)}
        end

        if type(val) == "function" then
            val = val(unpack(args))
        end

        result = val
    end

    return result
end

local function stash_set(stash, k, v, default)
    if default then
        local old = stash[k]
        if old == nil then
            stash[k] = v
        end
    else
        stash[k] = v
    end
end

_M.vmethods = {
    join = function (list, delim)
        delim = delim or ' '
        local out = {}
        local size = #list
        for i = 1, size, 1 do
            out[i * 2 - 1] = list[i]
            if i ~= size then
                out[i * 2] = delim
            end
        end
        return concat(out)
    end,

    first = function (list)
        return list[1]
    end,

    keys = function (list)
        local out = {}
        i = 1
        for key in pairs(list) do
            out[i] = key
            i = i + 1
        end
        return out
    end,

    last = function (list)
        return list[#list]
    end,

    push = function(list, ...)
        local n = select("#", ...)
        local m = #list
        for i = 1, n do
            list[m + i] = select(i, ...)
        end
        return ''
    end,

    size = function (list)
        if type(list) == "table" then
            return #list
        else
            return 1
        end
    end,

    sort = function (list)
        local out = { unpack(list) }
        table.sort(out)
        return out
    end,

    split = function (str, delim)
        delim = delim or ' '
        local out = {}
	local start = 1
	local sub = string.sub
	local find = string.find
	local sstart, send = find(str, delim, start)
        local i = 1
	while sstart do
	    out[i] = sub(str, start, sstart-1)
            i = i + 1
	    start = send + 1
	    sstart, send = find(str, delim, start)
	end
	out[i] = sub(str, start)
	return out
    end,
}

_M.filters = {
    html = function (s, args)
        s = gsub(s, "&", '&amp;', "jo")
        s = gsub(s, "<", '&lt;', "jo");
        s = gsub(s, ">", '&gt;', "jo");
        s = gsub(s, '"', '&quot;', "jo"); -- " end quote for emacs
        return s
    end,

    lower = function (s, args)
        return string.lower(s)
    end,

    upper = function (s, args)
        return string.upper(s)
    end,
}

function _M.process(file, params)
    local stash = params
    local context = {
        stash = stash,
        filter = function (bits, name, params)
            local s = concat(bits)
            local f = _M.filters[name]
            if f then
                return f(s, params)
            end
            return error("filter '" .. name .. "' not found")
        end
    }
    context = setmetatable(context, context_meta)
    local f = template_map[file]
    if not f then
        return error("file error - " .. file .. ": not found")
    end
    return f(context)
end
...
}

1;

__END__

=encoding utf8

=head1 Name

Lemplate - OpenResty/Lua template framework implementing Perl's TT2 templating language

=head1 Status

This is still under early development. Check back often.

=head1 Synopsis

From the command-line:

    lemplate --compile path/to/lemplate/directory/ > myapp/templates.lua

From OpenResty Lua code:

    local templates = require "myapp.templates"
    ngx.print(templates.process("homepage.tt2", { var1 = 32, var2 = "foo" }))

From the command-line:

    lemplate --compile path/to/lemplate/directory/ > myapp/templates.lua

=head1 Description

Lemplate is a templating framework for OpenResty/Lua that is built over
Perl's Template Toolkit (TT2).

Lemplate parses TT2 templates using the TT2 Perl framework, but with a twist.
Instead of compiling the templates into Perl code, it compiles them into Lua
that can run on OpenResty.

Lemplate then provides a Lua runtime module for processing the template code.
Presto, we have full featured Lua templating language!

Combined with OpenResty, Lemplate provides a really simple and powerful way to
do web stuff.

=head1 HowTo

Lemplate comes with a command line tool call C<lemplate> that you use to
precompile your templates into a Lua module file. For example if you have a
template directory called F<templates> that contains:

    $ ls templates/
    body.tt2
    footer.tt2
    header.tt2

You might run this command:

    $ lemplate --compile template/* > myapp/templates.lua

This will compile all the templates into one Lua module file which can be loaded in your
main OpenResty/Lua application as the module C<myapp.templates>.

Now all you need to do is load the Lua module file in your OpenResty app:

    local templates = require "myapp.templates"

and do the HTML page rendering:

    local results = templates.process("some-page.tt2",
                                      { var1 = val1, var2 = val2, ...})

Now you have Lemplate support for these templates in your OpenResty application.

=head1 Public API

The Lemplate Lua runtime module has the following API method:

=over

=item process(template-name, data)

The C<template-name> is a string like C<'body.tt2'> that is the name of
the top level template that you wish to process.

The optional C<data> specifies the data object to be used by the
templates. It can be an object, a function or a url. If it is an object,
it is used directly. If it is a function, the function is called and the
returned object is used.

=back

=head1 Current Support

The goal of Lemplate is to support all of the Template Toolkit features
that can possibly be supported.

Lemplate now supports almost all the TT directives, including:

    * Plain text
    * [% [GET] variable %]
    * [% CALL variable %]
    * [% [SET] variable = value %]
    * [% DEFAULT variable = value ... %]
    * [% INCLUDE [arguments] %]
    * [% PROCESS [arguments] %]
    * [% BLOCK name %]
    * [% FILTER filter %] text... [% END %]
    * [% WRAPPER template [variable = value ...] %]
    * [% IF condition %]
    * [% ELSIF condition %]
    * [% ELSE %]
    * [% SWITCH variable %]
    * [% CASE [{value|DEFAULT}] %]
    * [% FOR x = y %]
    * [% WHILE expression %]
    * [% RETURN %]
    * [% THROW type message %]
    * [% STOP %]
    * [% NEXT %]
    * [% LAST %]
    * [% CLEAR %]
    * [%# this is a comment %]
    * [% MACRO name(param1, param2) BLOCK %] ... [% END %]

ALL of the string virtual functions are supported.

ALL of the array virtual functions are supported:

ALL of the hash virtual functions are supported:

MANY of the standard filters are implemented.

The remaining features will be added very soon. See the DESIGN document
in the distro for a list of all features and their progress.

=head1 Community

=head2 English Mailing List

The L<openresty-en|https://groups.google.com/group/openresty-en> mailing list is for English speakers.

=head2 Chinese Mailing List

The L<openresty|https://groups.google.com/group/openresty> mailing list is for Chinese speakers.

=head1 Code Repository

The bleeding edge code is available via Git at
git://github.com/openresty/lemplate.git

=head1 Bugs and Patches

Please submit bug reports, wishlists, or patches by

=over

=item 1.

creating a ticket on the L<GitHub Issue Tracker|https://github.com/openresty/lua-nginx-module/issues>,

=item 2.

or posting to the L</Community>.

=back

=head1 Credit

This project is based on Ingy dot Net's excellent L<Jemplate> project.

=head1 Author

Yichun Zhang (agentzh), E<lt>agentzh@gmail.comE<gt>, OpenResty Inc.

=head1 Copyright

Copyright (C) 2016-2017 Yichun Zhang (agentzh).  All Rights Reserved.

Copyright (C) 1996-2014 Andy Wardley.  All Rights Reserved.

Copyright (c) 2006-2014. Ingy döt Net. All rights reserved.

Copyright (C) 1998-2000 Canon Research Centre Europe Ltd

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 See Also

=over

=item *

Perl TT2 Reference Manual: http://www.template-toolkit.org/docs/manual/index.html

=item *

Jemplate for compiling TT2 templates to client-side JavaScript: http://www.jemplate.net/

=back
