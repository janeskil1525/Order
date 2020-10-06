#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Order::Helper::Orion::Reservation;;

sub add_reservation {

    my $pg = Mojo::Pg->new->dsn(
        "dbi:Pg:dbname=Order;host=192.168.1.100;port=15432;user=postgres;password=PV58nova64"
    );

    my $data;
    my $config;
    $config->{orion}->{address} = 'https://testwss.bosab.se/';
    $config->{orion}->{reservation_endpoint_path} = 'SaveReservations';

    my $task = Order::Helper::Orion::Reservation->new(
        config => $config,
    );
    my $stockitem = '22569490';
    my $company = 'F';
    my $type = '2';
    my $settings->{username} = 'Norr';
    $settings->{password} = 'q81k';
    my $result = $task->add_reservation($stockitem, $company, $type,$settings);

    say $result;

    return $result;

}

ok(add_reservation() == 1);
done_testing();

