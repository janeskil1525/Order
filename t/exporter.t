use Mojo::Base -strict, -signatures, -async_await;
use Test::More;

use Mojo::Pg;
use Order::Helper::Order::Export;

my $pg = Mojo::Pg->new->dsn(
    "dbi:Pg:dbname=Order;host=192.168.1.100;port=15432;user=postgres;password=PV58nova64"
);

async sub export {

    my $order = await Order::Helper::Order::Export->new(
        pg => $pg
    )->export_orders(
        'orion'
    );

    return $order;
}

ok(export() == 1);
done_testing();

