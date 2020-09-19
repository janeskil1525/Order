package Order::Model::BasketAdresses;
use Mojo::Base 'Daje::Utils::Sentinelsender';

has 'pg';

sub load_adresses_for_order{
    my ($self, $basketid) = @_;

    my $stmt = qq {
        SELECT name, address1, address2, address3, city, zipcode, country, address_type
        FROM basket INNER JOIN  basket_addresses_basket
        ON basket_pkey = basket_fkey AND basketid = ?
        INNER JOIN basket_addresses
        ON basket_addresses_fkey = basket_addresses_pkey
    };

    my $addresses = $self->pg->db->query(
        $stmt, ($basketid)
    );

    my $hash;
    $hash = $addresses->hashes if $addresses->rows > 0;

    return $hash;
}
1;