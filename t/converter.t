#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Order::Helper::Shoppingcart::Converter;

use Mojo::Pg;

my $pg = Mojo::Pg->new->dsn(
    "dbi:Pg:dbname=Order;host=192.168.1.108;port=5432;user=postgres;password=PV58nova64"
);

sub convert {

    # my $result = $pg->db->select('minion_jobs',['args'],{ id => 4564781 });
    # my $import_json = decode_json($result->hash->{args});
    # my $import_json_ref = from_json(@{$import_json}[0]);

    my $data->{basket_pkey} = 40;
    $data->{basketid} = 'f39222f9-c3ed-56ac-e6f5-cf73b3a6ddc2';

    my $config->{webshop}->{address} = 'https://lagapro.laga.se';
    $config->{webshop}->{key} = '8542f1f2-1dcd-4446-a97f-e5661d6d3412';
    $config->{webshop}->{messenger_endpoint} = '/api/vi/messenger/add/notice/';

    my $result = Order::Helper::Shoppingcart::Converter->new(
        pg => $pg
    )->create_orders_test(
        $pg, $data, $config
    );

    return $result;
}

ok(convert == 1);

done_testing();

