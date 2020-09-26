#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Order::Helper::Rfqs;

sub test_send_rfq{

    my $pg = Mojo::Pg->new->dsn(
        "dbi:Pg:dbname=Order;host=192.168.1.108;port=5432;user=postgres;password=PV58nova64"
    );

    my $data = $pg->db->select('minion_jobs',['args'],{ id => 4 });

    my $config->{webshop}->{address} = 'https://lagapro.laga.se';
    $config->{webshop}->{key} = '8542f1f2-1dcd-4446-a97f-e5661d6d3412';
    $config->{webshop}->{messenger_endpoint} = '/api/vi/messenger/add/notice/';

    my $result = Order::Helper::Rfqs->new()->send_rfq_test($pg, $config, $data);

    return $result;
}

ok(test_send_rfq eq 'Success');
done_testing();

