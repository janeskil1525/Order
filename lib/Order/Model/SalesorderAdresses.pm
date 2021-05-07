package Order::Model::SalesorderAdresses;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Try::Tiny;

has 'pg';

sub load_salesorder_addresses ($self, $order_head_pkey, $type) {

    my $stmt = qq {
        SELECT * FROM salesorder_addresses_salesorder JOIN sales_order_addresses
            ON sales_order_addresses_pkey = sales_order_addresses_fkey
        WHERE sales_order_head_fkey = ? AND address_type = ?
    };

    my $result = try {
         return $self->pg->db->query(
             $stmt,($order_head_pkey, $type)
        );

    } catch {
        say $_;
    };

    my $hash;
    $hash = $result->hash if $result and $result->rows > 0;

    return $hash;
}

async sub load_salesorder_addresses_async ($self, $order_head_pkey, $type) {

    my $stmt = qq {
        SELECT * FROM salesorder_addresses_salesorder JOIN sales_order_addresses
            ON sales_order_addresses_pkey = sales_order_addresses_fkey
        WHERE sales_order_head_fkey = ? AND address_type = ?
    };

    my $result = try {
        return $self->pg->db->query(
            $stmt,($order_head_pkey, $type)
        );

    } catch {
        say $_;
    };

    my $hash;
    $hash = $result->hash if $result and $result->rows > 0;

    return $hash;
}
1;