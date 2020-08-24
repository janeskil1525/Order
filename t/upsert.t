use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Pg;
use Mojo::JSON qw{encode_json};
# use Order::Helper::Shoppingcart;
use Data::Dumper;

helper pg => sub {
    state $pg = Mojo::Pg->new->dsn(
        "dbi:Pg:dbname=Order;host=192.168.1.100;port=15432;user=postgres;password=PV58nova64"
    )
};

my $t = Test::Mojo->new('Order');

post '/api/v1/basket/upsertitem/' => sub {
    my $c = shift;

    my $condition = $c->req->content->asset->slurp;
    my $result = $c->shoppingcart->upsertItem($condition);

    $c->render(json => $result->{result});
};

$t->post_ok('/api/v1/basket/upsertitem/' => {Accept => '*/*'} => json => {
    token       => 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F',
    basketid    => '123456543321234',
    stockitem   => '123456',
    quantity    => '1',
    price       => "100.00",
    itemno      => '10',
    supplier    => 'P',
    description => 'Test',
    company     => 'F',
    userid      => 'jan@daje.work',
    freight     => 100,
})->status_is(200)->json_has('result');;


done_testing();

