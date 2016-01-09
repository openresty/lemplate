use t::TestLemplate tests => 5;

my $input = "Foo <! bar !> baz!\n";

my $unexpected = <<'...';
output += 'Foo <! bar !> baz!\n';
...

my $expected = <<'...';
output += 'Foo ';
//line 1 "test_template"
output += stash.get('bar');
output += ' baz!\n';
...

#-------------------------------------------------------------------------------
{
    my $got = Lemplate->new(
    )->compile_template_content($input, 'test_template');

    is strip($got), $unexpected, 
        "Tags not changed";
}

#-------------------------------------------------------------------------------
{
    my $got = Lemplate->new(
        START_TAG => '<!',
        END_TAG => '!>',
    )->compile_template_content($input, 'test_template');

    is strip($got), $expected, 
        "Options passed into object";
}

#-------------------------------------------------------------------------------
{
    my ($template_options, $jemplate_options) = Lemplate->get_options(qw(
        --compile
    )); 
    my $got = Lemplate->new(
        %$template_options,
    )->compile_template_content($input, 'test_template');

    is strip($got), $unexpected, 
        "No options set";
}

#-------------------------------------------------------------------------------
{
    my ($template_options, $jemplate_options) = Lemplate->get_options(qw(
        --compile
        --start-tag=<!
        --end-tag=!>
    )); 
    my $got = Lemplate->new(
        %$template_options,
    )->compile_template_content($input, 'test_template');

    is strip($got), $expected, 
        "Options set in command line";
}

#-------------------------------------------------------------------------------
{
    $ENV{JEMPLATE_START_TAG} = '<!';
    $ENV{JEMPLATE_END_TAG} = '!>';
    my ($template_options, $jemplate_options) = Lemplate->get_options(qw(
        --compile
    )); 

    my $got = Lemplate->new(
        %$template_options,
    )->compile_template_content($input, 'test_template');

    is strip($got), $expected, 
        "Options set in enviroment variables";
}


#-------------------------------------------------------------------------------
sub strip {
    my $result = shift;
    $result =~ s/^Lemplate\.templateMap.*?    try \{\n//gsm;
    $result =~ s/^\s+\}\s+catch\(e\) \{\n.*?\n\}\n//gsm;
    $result =~ s/\n+\z/\n/;
    return $result;
}
