package t::TestLemplate;
use lib 'inc';
use Test::Base -Base;

use Lemplate;

package t::TestLemplate::Filter;
use base 'Test::Base::Filter';

sub XXX() { require YAML; die YAML::Dump(@_) }

sub parse {
    my $parser = Lemplate::Parser->new;
    my $template = $parser->parse(shift)
      or die $parser->error;
    return $template->{BLOCK};
}

sub parse_lite {
    no warnings 'redefine';
    local *Lemplate::Directive::template = sub {
        my ($class, $block) = @_;
        chomp($block);
        return "$block\n";
    };
    return $self->parse(@_);
}

sub compile {
    return Lemplate->compile_template_content(shift, 'test_template');
}

sub compile_lite {
    my $result = $self->compile(@_);
    $result =~ s/^Lemplate\.templateMap.*?    try \{\n//gsm;
    $result =~ s/^\s+\}\s+catch\(e\) \{\n.*?\n\}\n//gsm;
    $result =~ s/\n+\z/\n/;
    return $result;
}

sub X_line_numbers {
    my $js = shift;
    $js =~ s!^//line \d+!//line X!gm;
    return $js;
}
