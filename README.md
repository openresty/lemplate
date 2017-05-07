# Name

Lemplate - OpenResty/Lua template framework implementing Perl's TT2 templating language

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Synopsis](#synopsis)
* [Description](#description)
* [HowTo](#howto)
* [Public API](#public-api)
* [Current Support](#current-support)
* [Community](#community)
    * [English Mailing List](#english-mailing-list)
    * [Chinese Mailing List](#chinese-mailing-list)
* [Code Repository](#code-repository)
* [Bugs and Patches](#bugs-and-patches)
* [Credit](#credit)
* [Author](#author)
* [Copyright](#copyright)
* [See Also](#see-also)

# Status

This is still under early development. Check back often.

# Synopsis

From the command-line:

    lemplate --compile path/to/lemplate/directory/ > myapp/templates.lua

From OpenResty Lua code:

    local templates = require "myapp.templates"
    ngx.print(templates.process("homepage.tt2", { var1 = 32, var2 = "foo" }))

From the command-line:

    lemplate --compile path/to/lemplate/directory/ > myapp/templates.lua

# Description

Lemplate is a templating framework for OpenResty/Lua that is built over
Perl's Template Toolkit (TT2).

Lemplate parses TT2 templates using the TT2 Perl framework, but with a twist.
Instead of compiling the templates into Perl code, it compiles them into Lua
that can run on OpenResty.

Lemplate then provides a Lua runtime module for processing the template code.
Presto, we have full featured Lua templating language!

Combined with OpenResty, Lemplate provides a really simple and powerful way to
do web stuff.

[Back to TOC](#table-of-contents)

# HowTo

Lemplate comes with a command line tool call `lemplate` that you use to
precompile your templates into a Lua module file. For example if you have a
template directory called `templates` that contains:

    $ ls templates/
    body.tt2
    footer.tt2
    header.tt2

You might run this command:

    $ lemplate --compile template/* > myapp/templates.lua

This will compile all the templates into one Lua module file which can be loaded in your
main OpenResty/Lua application as the module `myapp.templates`.

Now all you need to do is load the Lua module file in your OpenResty app:

    local templates = require "myapp.templates"

and do the HTML page rendering:

    local results = templates.process("some-page.tt2",
                                      { var1 = val1, var2 = val2, ...})

Now you have Lemplate support for these templates in your OpenResty application.

[Back to TOC](#table-of-contents)

# Public API

The Lemplate Lua runtime module has the following API method:

- process(template-name, data)

    The `template-name` is a string like `'body.tt2'` that is the name of
    the top level template that you wish to process.

    The optional `data` specifies the data object to be used by the
    templates. It can be an object, a function or a url. If it is an object,
    it is used directly. If it is a function, the function is called and the
    returned object is used.

[Back to TOC](#table-of-contents)

# Current Support

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

[Back to TOC](#table-of-contents)

# Community

## English Mailing List

The [openresty-en](https://groups.google.com/group/openresty-en) mailing list is for English speakers.

[Back to TOC](#table-of-contents)

## Chinese Mailing List

The [openresty](https://groups.google.com/group/openresty) mailing list is for Chinese speakers.

[Back to TOC](#table-of-contents)

# Code Repository

The bleeding edge code is available via Git at
git://github.com/openresty/lemplate.git

[Back to TOC](#table-of-contents)

# Bugs and Patches

Please submit bug reports, wishlists, or patches by

1. creating a ticket on the [GitHub Issue Tracker](https://github.com/openresty/lua-nginx-module/issues),
2. or posting to the ["Community"](#community).

[Back to TOC](#table-of-contents)

# Credit

This project is based on Ingy dot Net's excellent [Jemplate](https://metacpan.org/pod/Jemplate) project.

[Back to TOC](#table-of-contents)

# Author

Yichun Zhang (agentzh), <agentzh@gmail.com>, OpenResty Inc.

[Back to TOC](#table-of-contents)

# Copyright

Copyright (C) 2016-2017 Yichun Zhang (agentzh).  All Rights Reserved.

Copyright (C) 1996-2014 Andy Wardley.  All Rights Reserved.

Copyright (c) 2006-2014. Ingy döt Net. All rights reserved.

Copyright (C) 1998-2000 Canon Research Centre Europe Ltd

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

[Back to TOC](#table-of-contents)

# See Also

- Perl TT2 Reference Manual: http://www.template-toolkit.org/docs/manual/index.html
- Jemplate for compiling TT2 templates to client-side JavaScript: http://www.jemplate.net/

[Back to TOC](#table-of-contents)

