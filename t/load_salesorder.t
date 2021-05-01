use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Order');
$t->get_ok('/api/v1/orders/load/sales/60' => {
    'X-Token-Check' => 'c6629f75-e46d-4829-adea-23451410b495'
})->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();

