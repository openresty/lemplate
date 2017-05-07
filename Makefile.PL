use strict;
use lib '.';
use inc::Module::Install;

name            ('Lemplate');
license         ('artistc');
perl_version    ('5.010001');
repository      ('https://github.com/openresty/test-nginx');
all_from        ('lib/Lemplate.pm');

requires        ('Template' => 2.14);
requires        ('File::Find::Rule');
build_requires  ('IPC::Run3');

use_test_base();
auto_install();

#tests('t/*.t t/*/*.t');

WriteAll();
