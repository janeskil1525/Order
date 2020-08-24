#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Order::Helper::Shoppingcart::Converter;

use Mojo::Pg;

my $pg = Mojo::Pg->new->dsn(
    "dbi:Pg:dbname=Order;host=192.168.1.100;port=15432;user=postgres;password=PV58nova64"
);

sub convert {

    # my $result = $pg->db->select('minion_jobs',['args'],{ id => 4564781 });
    # my $import_json = decode_json($result->hash->{args});
    # my $import_json_ref = from_json(@{$import_json}[0]);

    my $data->{basket_pkey} = 40;
    $data->{basketid} = 'f39222f9-c3ed-56ac-e6f5-cf73b3a6ddc2';

    my $result = Order::Helper::Shoppingcart::Converter->new(pg => $pg)->create_orders_test($pg,$data);

    return $result;
}

ok(convert == 1);

done_testing();

