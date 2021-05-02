package Order::Model::PurchaseorderAdresses;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Try::Tiny;

has 'pg';

sub load_purchase_order_addresses ($self, $order_head_pkey, $type) {

    my $stmt = qq {
        SELECT * FROM purchaseorder_addresses_purchaseorder JOIN purchase_order_addresses
            ON purchase_order_addresses_pkey = purchase_order_addresses_fkey
        WHERE purchase_order_head_fkey = ? AND address_type = ?
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