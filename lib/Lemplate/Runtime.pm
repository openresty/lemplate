package Lemplate::Runtime;
use strict;
use warnings;

# VERSION

sub main { return &kernel }
sub kernel {
    <<'...';
...
}

sub ajax_jquery {
    <<'...';
...
}

sub ajax_xhr {
    <<'...';
...
}

sub ajax_yui {
    <<'...';
...
}

sub json_json2 {
    <<'...';
...
}

sub json_json2_internal {
    <<'...';
;(function(){

var JSON;

}());
...
}

sub json_yui {
    <<'...';
...
}

sub json2 {
    <<'...';
...
}

sub xhr_gregory {
    <<'...';
...
}

sub xhr_ilinsky {
    <<'...';
...
}

sub xxx {
    <<'...';
...
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lemplate::Runtime - Perl Module containing the Lemplate Lua Runtime

=head1 SYNOPSIS

    use Lemplate::Runtime;
    print Lemplate::Runtime->main;

=head1 DESCRIPTION

This module is auto-generated and used internally by Lemplate. It
contains subroutines that simply return various parts of the Lemplate
Lua Runtime code.

=head1 METHODS

head2 kernel

head2 ajax_jquery

head2 ajax_xhr

head2 ajax_yui

head2 json_json2

head2 json_yui

head2 json2

head2 xhr_gregory

head2 xhr_ilinsky

head2 xxx

=head1 COPYRIGHT

Copyright (c) 2014. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
