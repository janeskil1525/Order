package Order::Helper::Order::CustomerData;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures;

use Try::Tiny;

has 'db';

sub insertCustomerData ($self, $customer, $salesorder_head_pkey) {

    $self->insert_address(
        $customer->{deliveryaddress}, $salesorder_head_pkey, 'Delivery'
    );

    $self->insert_address(
        $customer->{invoiceaddress}, $salesorder_head_pkey, 'Invoice'
    );


}

sub insert_address ($self, $address, $salesorder_head_pkey, $type) {

    my $sales_order_addresses_pkey = $self->db->insert(
        'sales_order_addresses',
        {
            name => $address->{name} ,
            address1 => $address->{address1},
            address2 => $address->{address2},
            address3 => $address->{address3},
            city => $address->{city},
            zipcode => $address->{zipcode},
            country => $address->{country},
        },
        {
            'returning' => 'sales_order_addresses_pkey'
        }
    )->hash->{sales_order_addresses_pkey};

    $self->db->insert(
        'salesorder_addresses_salesorder',
            {
                sales_order_addresses_fkey => $sales_order_addresses_pkey,
                sales_order_head_fkey      => $salesorder_head_pkey,
                address_type               => $type
            }
    );
}
1;