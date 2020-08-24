#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Mojo::Pg;

use Order::Helper::Shoppingcart;
use Mojo::JSON qw {encode_json};

my $pg = Mojo::Pg->new->dsn(
    "dbi:Pg:dbname=Order;host=192.168.1.100;port=15432;user=postgres;password=PV58nova64"
);

my $item;
$item->{token}           = 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F';
    $item->{basketid}        = '123456543321234';
    $item->{stockitem}       = '123456';
    $item->{quantity}        = '1';
    $item->{price}           = "100.00";
    $item->{itemno}          = '10';
    $item->{supplier}        = 'P';
    $item->{description}     = 'Test';
    $item->{company}     = 'F';
    $item->{userid}     = 'jan@daje.work';

sub upsertitem {

    my $basket = Order::Helper::Shoppingcart->new(pg => $pg);

    my $item_json = encode_json($item);

    my $test = $basket->upsertItem($item_json);

    return 1;
}
ok(upsertitem());
done_testing();

