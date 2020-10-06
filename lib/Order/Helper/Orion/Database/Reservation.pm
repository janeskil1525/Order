package Order::Helper::Orion::Database::Reservation;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Try::Tiny;

has 'orion';

sub check_reservation {
    my ($self, $stockitemid) = @_;

    my $stmt;

    $stmt = qq{SELECT id FROM Reservation WHERE DelartId = '$stockitemid'};
    my $id = try {
        $self->orion->get_dbh unless $self->orion->dbconnected ;
        my $id = $self->orion->dbh->selectrow_hashref($stmt);
        $id->{id} = 0 unless exists $id->{id};
        $id->{error} = '';
        return $id;
    } catch {
        $self->capture_message('','Daje-Orion', (ref $self), (caller(0))[3], $_);
        return {
            error => "Daje::Orion::Database::Stockitem:find_stockitem caught error: '$_' ",
            id => 0
        };
    };
    return $id;
}

1;