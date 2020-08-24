use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Pg;
use Mojo::JSON qw{encode_json};
# use Order::Helper::Shoppingcart;
use Data::Dumper;

my $t = Test::Mojo->new('Order');

$t->get_ok('/api/v1/basket/load/40c2d3b3-c0a1-eab8-ce49-fee02b065a5e')->status_is(200)->json_has('/basket');

done_testing();

