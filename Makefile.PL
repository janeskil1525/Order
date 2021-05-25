use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install qw{install_share};

install_share  'share';

WriteMakefile(
    NAME => 'Order',
    VERSION   => '0.0.5',
    PREREQ_PM => {'Mojolicious' => '8.33'},
    test      => {TESTS => 't/*.t'},
    AUTHOR       => 'Jan Eskilsson <janeskil1525@cpan.org>',
    EXE_FILES    => [ qw{
        script/order
    }],
);

package MY;
use File::ShareDir::Install qw(postamble);
