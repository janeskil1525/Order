package Order::Helper::Orion::Processor;
use Mojo::Base 'Matorit::Orion::Communicator::Base;';

use Mojo::JSON qw{to_json};
use Order::Helper::Orion::Data::OrderHead;
use Order::Helper::Orion::Data::OrderItem;
use Order::Model::SalesOrderHead;
use Order::Model::SalesOrderItem;
use Order::Model::BasketAdresses;

has 'pg';
has 'config';

sub process_order {
    my ($self, $salesorderhead_pkey) = @_;


    my $ordehead = $self->load_orderhead($salesorderhead_pkey);
    my $addresses = $self->load_addresses($ordehead->{externalref});
    my $orderitems = $self->load_orderitems($salesorderhead_pkey);
    my $orionorderitems = $self->create_orion_orderitem($orderitems);
    my $orion_order = $self-create_orion_order($ordehead, $orionorderitems, $addresses);

    my $result = $self->send_order($orion_order);

    return $result;
}

sub send_order {
    my ($self, $orion_order) = @_;

    my $result;
    my $orion_order_json = to_json $orion_order;
    my $res = $self->post_data($orion_order_json)->result;
    if($res->is_success)  {
        $result eq '1';
    } elsif ($res->is_error){
        say  $res->message . ' ' . $res->code . ' ' . $res->body;
        $result = $res->message . ' ' . $res->code . ' ' . $res->body;
    }

    return $result;
}

sub create_orion_order {
    my ($self, $ordehead, $orderitems, $addresses) = @_;

    my $orionorder = Order::Helper::Orion::Data::OrderHead->new(
        'carbreaker' => $order->{company},
        'customerorderno' => $order->{order_no},
        'customerref' => $order->{userid},
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
        'rows' => $orderitems,
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
            'articleno' => $item->{extradata}->{articleno},
            'carbreaker' => $item->{extradata}->{carbreaker},
            'customerno' => '1234',
            'customerorderno' => '234234',
            'discount' => 0,
            'kind' => 'D',
            'orderingcarbreaker' => 'F',
            'originalno' => $item->{extradata}->{originalno},
            'partdesignation' => '3',
            'partid' => $item->{extradata}->{id},
            'position' => $position,
            'quality' => $item->{extradata}->{quality},
            'quantity' => 1,
            'referencenumber' => $item->{extradata}->{referencenumber},
            'remark' => $item->{extradata}->{remark},
            'sbrcarcode' => $item->{extradata}->{sbrcarcode},
            'sbrpartcode' => $item->{extradata}->{sbrpartcode},
            'lagawarranty' => '',
            'priceperitem' => $item->{extradata}->{price},
        )->hash();
        push @orionitems, $orionitem;
        $position++;
    }

    return \@orionitems;
}


sub load_orderitems {
    my ($self, $salesorderhead_pkey) = @_;

    my $ordehead = Order::Model::SalesOrderItem->new(
        pg => $self->pg
    )->load_order_items(
        $salesorderhead_pkey
    )->hashes;

    return $ordehead;
}

sub load_orderhead {
    my ($self, $salesorderhead_pkey) = @_;

    my $ordehead = Order::Model::SalesOrderHead->new(
        pg => $self->pg
    )->load_order_head(
        $salesorderhead_pkey
    )->hash;

    return $ordehead;
}

sub load_addresses{
    my ($self, $basketid) = @_;

    my $adresses;
    my $adressesarr = Order::Model::BasketAdresses->new(
        pg => $self-pg
    )->load_adresses_for_order(
        $basketid
    );

    foreach my $address (@{$adressesarr}) {
        $adresses->{$address->{address_type}} = $address;
    }

    return $adresses;
}
1;