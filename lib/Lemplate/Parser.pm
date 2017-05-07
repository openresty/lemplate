package Lemplate::Parser;
use strict;
use warnings;
use base 'Template::Parser';

our $VERSION = '0.11';

use Lemplate::Grammar;
use Lemplate::Directive;

sub new {
    my $class = shift;
    my $parser = $class->SUPER::new(
        GRAMMAR => Lemplate::Grammar->new(),
        FACTORY => 'Lemplate::Directive',
        @_,
    );

    # flags passed from Lemplate object
    my %args = @_;

    # eval-javascript is default "on"
    $parser->{EVAL_JAVASCRIPT} = exists $args{EVAL_JAVASCRIPT}
      ? $args{EVAL_JAVASCRIPT} : 1;

    # tie the parser state-variable to the global Directive var
    $parser->{INJAVASCRIPT} = \$Lemplate::Directive::INJAVASCRIPT;

    return $parser;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Lemplate::Parser - Lemplate Parser Subclass

=head1 SYNOPSIS

    use Lemplate::Parser;

=head1 DESCRIPTION

Lemplate::Parser is a simple subclass of Template::Parser. Not much
to see here.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2014. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
