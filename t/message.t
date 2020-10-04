#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Order::Helper::Messenger::Message;


use Mojo::Pg;

my $pg = Mojo::Pg->new->dsn(
    "dbi:Pg:dbname=Order;host=192.168.1.108;port=5432;user=postgres;password=PV58nova64"
);

sub send_message_test {

    my $data = $pg->db->select('minion_jobs',['args'],{ id => 47 });
    #my $minion = Minion->new(Pg => $pg);
    my $import_json = decode_json($data->hash->{args});

    my $config->{webshop}->{address} = 'https://lagapro.laga.se';
    $config->{webshop}->{key} = '8542f1f2-1dcd-4446-a97f-e5661d6d3412';
    $config->{webshop}->{messenger_endpoint} = '/api/vi/messenger/add/notice/';

    my $result = Order::Helper::Messenger::Message->new(
        config => $config
    )->send_message_test($pg, $config, $import_json);

    return $result;
}

ok(send_message_test() == 1);
done_testing();

