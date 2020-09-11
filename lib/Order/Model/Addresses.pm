package Order::Model::Addresses;
use Mojo::Base -base;

use Order::Utils::Postgres::Columns;

use Try::Tiny;

has 'pg';

sub set_setdefault_data{
    my ($self, $data) = @_;

    my $fields;
    ($data, $fields) = Daje::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->set_setdefault_data($data, 'addresses');

    return $data, $fields;
}

sub get_table_column_names {
    my $self = shift;

    my $fields;
    $fields = Daje::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->get_table_column_names('addresses');

    return $fields;
}

sub save_address_p{
    my ($self, $data) = @_;

    return $self->pg->db->query_p(
        "INSERT INTO addresses
                    (name, address1, address2, city, zipcode, country)
                VALUES(?,?,?,?,?,?)
                    ON CONFLICT (name)
                DO UPDATE SET address1 = ?, address2 = ?, city = ?, zipcode = ?, country = ?
                    RETURNING addresses_pkey",
        (
            $data->{name},
            $data->{address1},
            $data->{address2},
            $data->{city},
            $data->{zipcode},
            $data->{country},
            $data->{address1},
            $data->{address2},
            $data->{city},
            $data->{zipcode},
            $data->{country},
        )
    );
}

1;
