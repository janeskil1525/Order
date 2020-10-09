package Order::Helper::Orion::Reservation;
use Mojo::Base 'Order::Helper::Orion::Communicator::Base';

use Mojo::JSON qw {to_json};

use Order::Helper::Orion::Database::Orion;
use Order::Helper::Orion::Database::Reservation;
use Order::Helper::Orion::Data::Reservation;
use Try::Tiny;

has 'config';
has 'orion';

sub check_reservation {
    my ($self, $stockitemid) = @_;

    my $orion = Order::Helper::Orion::Database::Orion->new(
        dbconnectstring => $self->config->{orionconnect}
    );

    my $id = try {
        my $id  = Order::Helper::Orion::Database::Reservation->new(
            orion => $orion
        )->check_reservation(
            $stockitemid
        );
        $orion->dbh->disconnect();
        $orion->dbconnected(0);
        return $id->{id};
    } catch {
        say $_;
        $self->capture_message(
            '', 'SOrder::Helper::Orion::Reservation::check_reservation',
            (ref $self), (caller(0))[3], $_
        );
        return 0;
    };

    return $id;
}

sub add_reservation {
    my ($self, $stockitem, $company, $type, $settings) = @_;

    my $reservation = Order::Helper::Orion::Data::Reservation->new(
        carbreaker      => $company,
        partid          => $stockitem,
        reservationtype => $type,
        id              => 0,
        #expired         => DateTime->now(),
        extreference    => 'Osatt',
        extsource       => 'LagaPro',
        #lastupdate      => DateTime->now(),
        usersign        => 'Jan'
    )->hash();

    $self->endpoint_address($self->config->{orion}->{address});
    $self->endpoint_path($self->config->{orion}->{reservation_endpoint_path});
    $self->username($settings->{username});
    $self->password($settings->{password});

    my $result;
    my $reservations;
    push @{$reservations->{reservations}}, $reservation;
    my $res = try {
        $self->post_data($reservations)->result;
    } catch {
        say $_;
        $self->capture_message(
            '','SOrder::Helper::Orion::Reservation::add_reservation',
                (ref $self), (caller(0))[3], $_
        ) ;
    };

    if($res->is_success)  {
        $result = $res->body;
    } elsif ($res->is_error){
        say  $res->message . ' ' . $res->code . ' ' . $res->body;
        $self->capture_message(
            '','SOrder::Helper::Orion::Reservation::add_reservation',
            (ref $self), (caller(0))[3], $result
        ) ;
        $result = 0;
    }

    return $result;
}
1;