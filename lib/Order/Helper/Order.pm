package Order::Helper::Order;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Model::PurchaseOrderHead;
use Order::Model::SalesOrderHead;
use Order::Model::SalesOrderItem;

use Order::Model::OrderCompanies;
use Order::Model::OrderAddresses;
use Order::Helper::Order::Summary;

use Try::Tiny;

has 'pg';

sub get_order_company{
    my ($self, $order_head_pkey) = @_;

    return Order::Model::PurchaseOrderHead->new(
        pg => $self->pg
    )->get_company(
        $order_head_pkey
    );
}

sub get_order_summary{
    my ($self, $order_head_pkey) = @_;

    return Order::Helper::Order::Summary->new(
        pg => $self->pg
    )->get_summary(
        $order_head_pkey
    );
}

sub loadOpenOrderList{
    my ($self, $companies_fkey, $type, $grid_fields_list) = @_;

    my $order;
    if($type == 1) {
        $order->{data} = $self->loadOpenPurchaseOrderList($companies_fkey, $grid_fields_list);
    } else {
        $order->{data} = $self->loadOpenSalesOrderList($companies_fkey, $grid_fields_list);
    }

    return $order;
}

sub loadOpenPurchaseOrderList{
    my ($self, $companies_fkey, $grid_fields_list) = @_;

    my $order->{data} = Order::Model::PurchaseOrderHead->new(
        pg => $self->pg
    )->loadOpenOrderList($companies_fkey, $grid_fields_list);
    return $order;
}

sub loadOpenSalesOrderList{
    my ($self, $companies_fkey, $grid_fields_list) = @_;

    my $order->{data} = Order::Model::SalesOrderHead->new(
        pg => $self->pg
    )->loadOpenOrderList($companies_fkey, $grid_fields_list);
    return $order;
}

sub set_setdefault_purchaseitem_data{
    my ($self, $data) = @_;

    return Order::Model::PurchaseOrderItem->new(
        pg => $self->pg
    )->set_setdefault_data($data);
}

sub set_setdefault_salesitem_data{
    my ($self, $data) = @_;

    return Order::Model::SalesOrderItem->new(
        pg => $self->pg
    )->set_setdefault_data($data);
}

sub load_order_head{
    my ($self, $order_head_pkey, $type) = @_;

    my $order_head;
    if($type == 1){
        $order_head = $self->load_salesorder_head($order_head_pkey);
    } else {
        $order_head = $self->load_purchaseorder_head($order_head_pkey);
    }
    return $order_head;
}

sub load_salesorder_head{
    my ($self, $order_head_pkey, $type) = @_;

    return Order::Model::SalesOrderHead->new(
        pg => $self->pg
    )->load_order_head($order_head_pkey)
}

sub load_purchaseorder_head{
    my ($self, $order_head_pkey, $type) = @_;

    return Order::Model::PurchaseOrderHead->new(
        pg => $self->pg
    )->load_order_head($order_head_pkey)
}

sub load_order_addresses_p{
    my ($self, $order_head_pkey) = @_;

    return Order::Model::OrderAddresses->new(
        pg => $self->pg
    )->load_order_addresses_p($order_head_pkey);
}

1;