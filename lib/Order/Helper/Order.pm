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

sub get_table_column_names{
    my $self = shift;

    my $ordercompanies = try {
        Order::Model::Companies->new(
            pg => $self->pg
        )->get_table_column_names();
    }catch{
        $self->capture_message("[Daje::Order::Order::get_table_column_names Companies] " . $_);
        say $_;
    };

    my $orderaddresses = try{
        Order::Model::OrderAddresses->new(
            pg => $self->pg
        )->get_table_column_names();
    }catch{
        $self->capture_message("[Daje::Order::Order::get_table_column_names OrderAddresses] " . $_);
        say $_;
    };

    my $orderhead = try{
        Order::Model::OrderHead->new(
            pg => $self->pg
        )->get_table_column_names();
    }catch{
        $self->capture_message("[Daje::Order::Order::get_table_column_names OrderHead] " . $_);
        say $_;
    };
    return ($orderhead, $orderaddresses, $ordercompanies);
}

sub get_table_default_data{
    my $self = shift;

    my $ordercompanies = try {
        my ($data, $fields);
        ($data, $fields) = Order::Model::Companies->new(
            pg => $self->pg
        )->set_setdefault_data();

        my $table->{data} = $data;
        $table->{fields} = $fields;
        return $table;
    }catch{
        $self->capture_message("[Daje::Order::Order::get_table_default_data Companies] " . $_);
        say $_;
    };

    my $orderaddresses = try{
        my ($data, $fields);
        ($data, $fields) = Order::Model::OrderAddresses->new(
            pg => $self->pg
        )->set_setdefault_data();

        my $table->{data} = $data;
        $table->{fields} = $fields;
        return $table;
    }catch{
        $self->capture_message("[Daje::Order::Order::get_table_default_data OrderAddresses] " . $_);
        say $_;
    };

    my $orderhead = try{
        my ($data, $fields);
        ($data, $fields) = Order::Model::OrderHead->new(
            pg => $self->pg
        )->set_setdefault_data($data);
        my $table->{data} = $data;
        $table->{fields} = $fields;
        return $table;
    }catch{
        $self->capture_message("[Daje::Order::Order::get_table_default_data OrderHead] " . $_);
        say $_;
    };

    my $table->{orderhead} = $orderhead;
    $table->{orderaddresses} = $orderaddresses;
    $table->{ordercompanies} = $ordercompanies;

    return $table;
}


1;