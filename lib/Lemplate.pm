# ToDo:
# - Use TT:Simple in Makefiles

package Lemplate;
use strict;
use warnings;
use Template 2.14;
use Getopt::Long;

# VERSION

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
    require Lemplate::Runtime;
    require Lemplate::Runtime::Compact;

    unshift @_, "standard" unless @_;

    my ($runtime, $ajax, $json, $xhr, $xxx, $compact) = map { defined $_ ? lc $_ : "" } @_[0 .. 5];

    my $Lemplate_Runtime = $compact ? "Lemplate::Runtime::Compact" : "Lemplate::Runtime";

    if ($runtime eq "standard") {
        $ajax ||= "xhr";
        $json ||= "json2";
        $xhr ||= "ilinsky";
    }
    elsif ($runtime eq "jquery") {
        $ajax ||= "jquery";
    }
    elsif ($runtime eq "yui") {
        $ajax ||= "yui";
        $json ||= "yui";
    }
    elsif ($runtime eq "legacy") {
        $ajax ||= "xhr";
        $json ||= "json2";
        $xhr ||= "gregory";
        $xxx = 1;
    }
    elsif ($runtime eq "lite") {
    }

    $ajax = "xhr" if $ajax eq 1;
    $xhr ||= 1 if $ajax eq "xhr";
    $json = "json2" if $json eq 1;
    $xhr = "ilinsky" if $xhr eq 1;

    my @runtime;

    push @runtime, $Lemplate_Runtime->kernel if $runtime;

    push @runtime, $Lemplate_Runtime->json2 if $json =~ m/^json2?$/i;

    push @runtime, $Lemplate_Runtime->ajax_xhr if $ajax eq "xhr";
    push @runtime, $Lemplate_Runtime->ajax_jquery if $ajax eq "jquery";
    push @runtime, $Lemplate_Runtime->ajax_yui if $ajax eq "yui";

    push @runtime, $Lemplate_Runtime->json_json2 if $json =~ m/^json2?$/i;
    push @runtime, $Lemplate_Runtime->json_json2_internal if $json =~ m/^json2?[_-]?internal$/i;
    push @runtime, $Lemplate_Runtime->json_yui if $json eq "yui";

    push @runtime, $Lemplate_Runtime->xhr_ilinsky if $xhr eq "ilinsky";
    push @runtime, $Lemplate_Runtime->xhr_gregory if $xhr eq "gregory";

    push @runtime, $Lemplate_Runtime->xxx if $xxx;

    return join ";", @runtime;
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
    version = '0.01'
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

local function stash_get(stash, k)
    local v
    if type(k) == "table" then
        v = stash
        for i = 1, #k, 2 do
            local key = k[i]
            local typ = k[i + 1]
            if type(typ) == "table" then
                local value = v[key]
                if type(value) == "function" then
                    return value()
                end
                if value then
                    return value
                end
                if key == "size" then
                    if type(v) == "table" then
                        return #v
                    else
                        return 1
                    end
                else
                    return error("virtual method " .. key .. " not supported")
                end
            end
            if type(key) == "number" and key == math_floor(key) and key >= 0 then
                key = key + 1
            end
            if type(v) ~= "table" then
                return nil
            end
            v = v[key]
        end
    else
        v = stash[k]
    end
    if type(v) == "function" then
        return v()
    end
    return v
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

function _M.process(file, params)
    local stash = params
    local context = {
        stash = stash,
        filter = function (bits, name, params)
            local s = concat(bits)
            if name == "html" then
                s = gsub(s, "&", '&amp;', "jo")
                s = gsub(s, "<", '&lt;', "jo");
                s = gsub(s, ">", '&gt;', "jo");
                s = gsub(s, '"', '&quot;', "jo"); -- " end quote for emacs
                return s
            end
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

=head1 NAME

Lemplate - JavaScript Templating with Template Toolkit

=head1 NAME

Lemplate - JavaScript Templating with Template Toolkit

=head1 SYNOPSIS

    var data = Ajax.get('url/data.json');
    var elem = document.getElementById('some-div');
    elem.innerHTML = Lemplate.process('my-template.html', data);

or:

    var data = Ajax.get('url/data.json');
    var elem = document.getElementById('some-div');
    Lemplate.process('my-template.html', data, elem);

or simply:

    Lemplate.process('my-template.html', 'url/data.json', '#some-div');

or, with jQuery.js:

    jQuery.getJSON("url/data.json", function(data) {
        Lemplate.process('my-template.html', data, '#some-div');
    });

From the commandline:

    lemplate --runtime --compile path/to/lemplate/directory/ > lemplate.js

=head1 DESCRIPTION

Lemplate is a templating framework for JavaScript that is built over
Perl's Template Toolkit (TT2).

Lemplate parses TT2 templates using the TT2 Perl framework, but with a
twist. Instead of compiling the templates into Perl code, it compiles
them into JavaScript.

Lemplate then provides a JavaScript runtime module for processing
the template code. Presto, we have full featured JavaScript
templating language!

Combined with JSON and xmlHttpRequest, Lemplate provides a really simple
and powerful way to do Ajax stuff.

=head1 HOWTO

Lemplate comes with a command line tool call C<lemplate> that you use to
precompile your templates into a JavaScript file. For example if you have
a template directory called C<templates> that contains:

    > ls templates/
    body.html
    footer.html
    header.html

You might run this command:

    > lemplate --compile template/* > js/lemplates.js

This will compile all the templates into one JavaScript file.

You also need to generate the Lemplate runtime.

    > lemplate --runtime > js/Lemplate.js

Now all you need to do is include these two files in your HTML:

    <script src="js/Lemplate.js" type="text/javascript"></script>
    <script src="js/lemplates.js" type="text/javascript"></script>

Now you have Lemplate support for these templates in your HTML document.

=head1 PUBLIC API

The Lemplate.js JavaScript runtime module has the following API method:

=over

=item Lemplate.process(template-name, data, target);

The C<template-name> is a string like C<'body.html'> that is the name of
the top level template that you wish to process.

The optional C<data> specifies the data object to be used by the
templates. It can be an object, a function or a url. If it is an object,
it is used directly. If it is a function, the function is called and the
returned object is used. If it is a url, an asynchronous <Ajax.get> is
performed. The result is expected to be a JSON string, which gets turned
into an object.

The optional C<target> can be an HTMLElement reference, a function or a
string beginning with a C<#> char. If the target is omitted, the
template result is returned. If it is a function, the function is called
with the result. If it is a string, the string is used as an id to find
an HTMLElement.

If an HTMLElement is used (by id or directly) then the innerHTML
property is set to the template processing result.

=back

The Lemplate.pm Perl module has the following public class methods,
although you won't likely need to use them directly. Normally, you just
use the C<lemplate> command line tool.

=over

=item Lemplate->compile_template_files(@template_file_paths);

Take a list of template file paths and compile them into a module of
functions. Returns the text of the module.

=item Lemplate->compile_template_content($content, $template_name);

Compile one template whose content is in memory. You must provide a
unique template name. Returns the JavaScript text result of the
compilation.

=item Lemplate->compile_module($module_path, \@template_file_paths);

Similar to `compile_template_files`, but prints to result to the
$module_path. Returns 1 if successful, undef if error.

=item Lemplate->compile_module_cached($module_path, \@template_file_paths);

Similar to `compile_module`, but only compiles if one of the templates
is newer than the module. Returns 1 if successful compile, 0 if no
compile due to cache, undef if error.

=back

=head1 AJAX AND JSON METHODS

Lemplate comes with builtin Ajax and JSON support.

=over

=item Ajax.get(url, [callback]);

Does a GET operation to the url.

If a callback is provided, the operation is asynchronous, and the data
is passed to the callback. Otherwise, the operation is synchronous and
the data is returned.

=item Ajax.post(url, data, [callback]);

Does a POST operation to the url.

Same callback rules as C<get> apply.

=item JSON.stringify(object);

Return the JSON serialization of an object.

=item JSON.parse(jsonString);

Turns a JSON string into an object and returns the object.

=back

=head1 CURRENT SUPPORT

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
  * [% JAVASCRIPT %] code... [% END %]
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

=head1 BROWSER SUPPORT

Tested successfully in:

    * Firefox Mac/Win32/Linux
    * IE 6.0
    * Safari
    * Opera
    * Konqueror

All tests run 100% successful in the above browsers.

=head1 DEVELOPMENT

The bleeding edge code is available via Git at
git://github.com/ingydotnet/lemplate.git

You can run the runtime tests directly from
http://svn.lemplate.net/repo/trunk/tests/run/index.html or from the
corresponding CPAN or JSAN directories.

Lemplate development is being discussed at irc://irc.freenode.net/#lemplate

If you want a committer bit, just ask ingy on the irc channel.

=head1 CREDIT

This module is only possible because of Andy Wardley's mighty Template
Toolkit. Thanks Andy. I will gladly give you half of any beers I
receive for this work. (As long as you are in the same room when I'm
drinking them ;)

=head1 AUTHORS

Ingy döt Net <ingy@cpan.org>

(Note: I had to list myself first so that this line would go into META.yml)

Lemplate is truly a community authored project:

Ingy döt Net <ingy@cpan.org>

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

Yann Kerherve <yannk@cpan.org>

David Davis <xantus@xantus.org>

Cory Bennett <coryb@corybennett.org>

Cees Hek <ceeshek@gmail.com>

Christian Hansen

David A. Coffey <dacoffey@cogsmith.com>

Robert Krimen <robertkrimen@gmail.com>

Nickolay Platonov <nickolay8@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2014. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
