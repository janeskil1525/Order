use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Pg;
use Mojo::JSON qw{encode_json};
# use Order::Helper::Shoppingcart;
use Data::Dumper;

my $t = Test::Mojo->new('Order');

$t->get_ok(
    '/api/v1/basket/load/e3be837e-c2ee-612a-81aa-3b81b05bf6af'
)->status_is(200)->json_has('/basket');

done_testing();

