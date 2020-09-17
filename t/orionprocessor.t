#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Mojo::JSON qw {from_json};
use DateTime;
use Order::Helper::Orion::Data::OrderHead;
use Order::Helper::Orion::Data::OrderItem;
use Order::Helper::Orion::Task;

sub get_orderhead {

    my $orderhead = Order::Helper::Orion::Data::OrderHead->new(
        'carbreaker' => 'F',
        'customerorderdate' => DateTime->now(),
        'customerorderno' => '1000',
        'customerref' => 'jan@daje.work',
        'extreference' => 'LagaPro',
        'extsource' => 'LagaPro',
        'freight' => 0,
        'invoiceaddress' => '',
        'invoicecity' => '',
        'invoicecountry' => '',
        'invoicename' => '',
        'invoicepostcode' => '',
        'kind' => "X",
        'orderdate' => DateTime->now(),
        'ourref' => 'janeskil1525@gmail.com',
        'discount' => 0,
        'paymentreference' => '',
        'salesperson' => '',
        'shippingaddress' => '',
        'shippingcity' => '',
        'shippingpostcode'=> '',
        'shippingcountry' => '',
        'shippingname' => '',
        'shippingsms' => '',
        'shippingphone' => '',
        'newsletteremail' => '',
        'newsletter' => '',
        'text' => '',
        'paymenttype'=> '' ,
        'orders' => [],
        'rows' => [],
        'vrno' => [],
        'invfee' => 0,
    );

    my $hash = $orderhead->hash();

    return ref $hash eq 'HASH';
}

sub get_orderhead_as_json {

    my $orderhead = Order::Helper::Orion::Data::OrderHead->new(
        'carbreaker' => 'F',
        'customerorderdate' => DateTime->now(),
        'customerorderno' => '1000',
        'customerref' => 'jan@daje.work',
        'extreference' => 'LagaPro',
        'extsource' => 'LagaPro',
        'freight' => 0,
        'invoiceaddress' => '',
        'invoicecity' => '',
        'invoicecountry' => '',
        'invoicename' => '',
        'invoicepostcode' => '',
        'kind' => "X",
        'orderdate' => DateTime->now(),
        'ourref' => 'janeskil1525@gmail.com',
        'discount' => 0,
        'paymentreference' => '',
        'salesperson' => '',
        'shippingaddress' => '',
        'shippingcity' => '',
        'shippingpostcode'=> '',
        'shippingcountry' => '',
        'shippingname' => '',
        'shippingsms' => '',
        'shippingphone' => '',
        'newsletteremail' => '',
        'newsletter' => '',
        'text' => '',
        'paymenttype'=> '' ,
        'orders' => [],
        'rows' => [],
        'vrno' => [],
        'invfee' => 0,
    );

    my $json = $orderhead->json();

    my $resp;
    return eval { $resp = from_json($json); 1 };

}

sub get_orderitem {

    my $orderitem = Order::Helper::Orion::Data::OrderItem->new(
        'articleno' => '1233444',
        'carbreaker' => 'F',
        'customerno' => '1234',
        'customerorderno' => '234234',
        'discount' => 0,
        'kind' => 'D',
        'orderingcarbreaker' => 'F',
        'originalno' => '12313ffd',
        'partdesignation' => '3',
        'partid' => '3333321',
        'position' => 0,
        'quality' => '*',
        'quantity' => 1,
        'referencenumber' => '3321',
        'remark' => 'red',
        'sbrcarcode' => '2222',
        'sbrpartcode' => '3333',
        'lagawarranty' => '',
        'priceperitem' => '140',
    );

    my $hash = $orderitem->hash();

    return ref $hash eq 'HASH';
}

sub get_orderitem_as_json {

    my $orderitem = Order::Helper::Orion::Data::OrderItem->new(
        'articleno' => '12345',
        'carbreaker' => 'F',
        'customerno' => '1234',
        'customerorderno' => '3456767',
        'discount' => 0,
        'dismantleddate' => DateTime->now(),
        'kind' => '',
        'orderingcarbreaker' => '',
        'originalno' => '1234',
        'partdesignation' => '',
        'partid' => '222222222',
        'position' => 0,
        'quality' => '*',
        'quantity' => 1,
        'referencenumber' => '222',
        'remark' => '',
        'sbrcarcode' => '0000',
        'sbrpartcode' => '2222',
        'lagawarranty' => '',
        'priceperitem' => 100,
    );

    my $json = $orderitem->json();

    my $resp;
    return eval { $resp = from_json($json); 1 };
}

sub process_orion_orders {

    my $pg = Mojo::Pg->new->dsn(
        "dbi:Pg:dbname=Order;host=192.168.1.100;port=15432;user=postgres;password=PV58nova64"
    );

    my $data;
    my $config;
    $config->{orion}->{address} = 'https://testwss.bosab.se/';
    $config->{orion}->{save_salesorder_endpoint} = 'SaveOrder';

    my $task = Order::Helper::Orion::Task->new(
        pg => $pg,
        endpoint_address => 'https://testwss.bosab.se/',
        endpoint_path => 'SaveOrder'
    );

    my $result = $task->process_orion_orders_test($pg, $config, $data);

    say $result;

    return $result;

}

ok(process_orion_orders() == 1);
ok(get_orderhead() == 1);
ok(get_orderhead_as_json() == 1);
ok(get_orderitem() == 1);
ok(get_orderitem_as_json() == 1);

done_testing();

