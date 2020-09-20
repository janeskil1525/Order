package Order::Helper::Orion::CreateOrder;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use DateTime;
use Order::Helper::Orion::Data::OrderHead;
use Order::Helper::Orion::Data::OrderItem;

sub orion_order {
    my ($self, $ordehead, $addresses, $orderitems) = @_;

    my $orionorderitems = $self->create_orion_orderitems($orderitems);
    my $orion_order = $self->create_orion_order($ordehead, $orionorderitems, $addresses);

    return $orion_order;
}

sub create_orion_order {
    my ($self, $ordehead, $orionorderitems, $addresses) = @_;

    my $orionorder = Order::Helper::Orion::Data::OrderHead->new(
        'carbreaker' => $ordehead->{company},
        'customerorderno' => $ordehead->{order_no},
        'customerref' => $ordehead->{userid},
        'extreference' => 'LagaPro',
        'extsource' => 'LagaPro',
        'freight' => 0,
        'invoiceaddress' => $addresses->{Invoice}->{address1},
        'invoicecity' => $addresses->{Invoice}->{city},
        'invoicecountry' => $addresses->{Invoice}->{country},
        'invoicename' => $addresses->{Invoice}->{name},
        'invoicepostcode' => $addresses->{Invoice}->{zipcode},
        'kind' => "X",
        'orderdate' => DateTime->now(),
        'ourref' => 'janeskil1525@gmail.com',
        'discount' => 0,
        'paymentreference' => '',
        'salesperson' => '',
        'shippingaddress' => $addresses->{Delivery}->{address1} ,
        'shippingcity' => $addresses->{Delivery}->{city},
        'shippingpostcode'=> $addresses->{Delivery}->{zipcode},
        'shippingcountry' => $addresses->{Delivery}->{country},
        'shippingname' => $addresses->{Delivery}->{name},
        'shippingsms' => '',
        'shippingphone' => '',
        'newsletteremail' => '',
        'newsletter' => '',
        'text' => '',
        'paymenttype'=> '' ,
        'orders' => [],
        'rows' => $orionorderitems,
        'vrno' => [],
        'invfee' => 0,
    )->hash();

    return $orionorder;
}

sub create_orion_orderitems{
    my ($self, $orderitems) = @_;

    my @orionitems;
    my $position = 1;
    foreach my $item (@{$orderitems}) {
        my $orionitem = Order::Helper::Orion::Data::OrderItem->new(
            'articleno'          => $item->{extradata_hash}->{articleno},
            'carbreaker'         => $item->{extradata_hash}->{carbreaker},
            'customerno'         => '1234',
            'customerorderno'    => '234234',
            'discount'           => 0,
            'kind'               => 'D',
            #'orderingcarbreaker' => 'F',
            'originalno'         => $item->{extradata_hash}->{originalno},
            'partdesignation'    => '3',
            'partid'             => $item->{extradata_hash}->{id},
            'position'           => $position,
            'quality'            => $item->{extradata_hash}->{quality},
            'quantity'           => 1,
            'referencenumber'    => $item->{extradata_hash}->{referencenumber},
            'remark'             => $item->{extradata_hash}->{remark},
            'sbrcarcode'         => $item->{extradata_hash}->{sbrcarcode},
            'sbrpartcode'        => $item->{extradata_hash}->{sbrpartcode},
            'lagawarranty'       => '',
            'priceperitem'       => $item->{extradata_hash}->{price},
            'type'               => 1,
        )->hash();
        push @orionitems, $orionitem;
        $position++;
    }

    return \@orionitems;
}
1;