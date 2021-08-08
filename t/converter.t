#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Mojo::JSON qw {from_json};
use Order::Helper::Shoppingcart::Converter;
use Messenger::Helper::Client;
use Mailer::Helper::Client;

use Mojo::Pg;
use Minion;

my $pg = Mojo::Pg->new->dsn(
    "dbi:Pg:dbname=Order;host=192.168.1.100;port=15432;user=postgres;password=PV58nova64"
);

sub convert {

    # my $result = $pg->db->select('minion_jobs',['args'],{ id => 4564781 });
    # my $import_json = decode_json($result->hash->{args});
    # my $import_json_ref = from_json(@{$import_json}[0]);

    my $result = $pg->db->select('minion_jobs',['args'],{ id => 27 });
    my $import_json = from_json($result->hash->{args});

    my $config->{messenger}->{endpoint_address} = 'http://127.0.0.1:3013';
    $config->{messenger}->{key} = '8542f1f2-1dcd-4446-a97f-e5661d6d3412';
    $config->{messenger}->{messenger_endpoint} = '/api/vi/messenger/add/notice/';

    $config->{mailer}->{key} = '8542f1f2-1dcd-4446-a97f-e5661d6d3412';
    $config->{mailer}->{endpoint_address} = 'mailer.laga.se';

    my $messenger = Messenger::Helper::Client->new(
        endpoint_address => $config->{messenger}->{endpoint_address},
        key              => $config->{messenger}->{key}
    );

    my $mailer= Mailer::Helper::Client->new(
        endpoint_address => $config->{mailer}->{endpoint_address},
        key              => $config->{mailer}->{key}
    );

    $result = Order::Helper::Shoppingcart::Converter->new(
        pg => $pg
    )->create_orders_test(
        $pg, @{$import_json}[0], $config, $messenger, $mailer
    );

    return $result;
}

ok(convert == 1);

done_testing();

