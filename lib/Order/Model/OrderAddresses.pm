package Order::Model::OrderAddresses;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Utils::Addresses::Company;
use Order::Utils::Postgres::Columns;
use Try::Tiny;

has 'pg';

sub load_order_addresses_p{
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select_p(
        ['order_addresses_order',['order_addresses',
            'order_addresses.order_addresses_pkey' => 'order_addresses_order.order_addresses_fkey']
        ],
        '*',
        {
            order_head_fkey => $order_head_pkey
        }
    );
}

sub load_order_addresses{
    my ($self, $order_head_pkey, $type) = @_;

    my $result = try {
        $self->pg->db->select(
            [ 'order_addresses_order', [ 'order_addresses',
                'order_addresses.order_addresses_pkey' => 'order_addresses_order.order_addresses_fkey' ]
            ],
            '*',
            {
                order_head_fkey => $order_head_pkey,
                address_type    => $type
            }
        );
    } catch {
        say $_;
    };

    my $hash;
    $hash = $result->hash if $result and $result->rows > 0;

    return $hash;
}

sub setSupplierAddresses{
    my ($self, $order_head_pkey, $suppliers_pkey) = @_;

    my $address = try {
        return Order::Utils::Addresses::Company->new(
            pg => $self->pg
        )->load_address($suppliers_pkey, 'invoice');
    }catch{
        $self->capture_message("[Daje::Model::OrderAddresses::setSupplierAddresses] " . $_);
        say $_;
        return
    };

    try {
        $self->createAddress($address, 'Supplier', $order_head_pkey)
    }catch{
        $self->capture_message("[Daje::Model::OrderAddresses::setSupplierAddresses] " . $_);
        say $_
    } if $address;

}

sub setCustomerAddresses{
    my ($self, $order_head_pkey, $data) = @_;

    if($data->{details}->{invoiceaddress}){
        $self->createAddress($data->{details}->{invoiceaddress}, 'Invoice', $order_head_pkey);
    }

    if($data->{details}->{deliveryaddress}){
        $self->createAddress($data->{details}->{deliveryaddress}, 'Delivery', $order_head_pkey);
    }

}

sub createAddress{
    my ($self, $address, $type, $order_head_pkey) = @_;

    my $order_addresses_pkey = $self->pg->db->insert('order_addresses',
        {
            name => $address->{name},
            address1 => $address->{address1},
            address2 =>  $address->{address2},
            address3 => $address->{address3},
            city => $address->{city} ,
            zipcode => $address->{zipcode},
            country => $address->{country} ,
        },{
            returning => 'order_addresses_pkey'
        })->hash->{order_addresses_pkey};

    $self->pg->db->insert('order_addresses_order',
        {
            order_head_fkey => $order_head_pkey,
            order_addresses_fkey => $order_addresses_pkey,
            address_type =>  $type,
        },{
            on_conflict => undef,
        });
}
sub set_setdefault_data{
    my ($self, $data) = @_;

    my $fields;
    ($data, $fields) = Order::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->set_setdefault_data($data, 'order_addresses');

    return $data, $fields;
}

sub get_table_column_names {
    my $self = shift;

    my $fields;
    $fields = Order::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->get_table_column_names('order_addresses');

    return $fields;
}
1;
