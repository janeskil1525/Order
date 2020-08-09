use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Order');
$t->get_ok('/api/v1/basket/open/jan@daje.work/A')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();
