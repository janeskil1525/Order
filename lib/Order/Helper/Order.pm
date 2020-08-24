package Order::Helper::Order;
use Mojo::Base 'Daje::Utils::Sentinelsender';


use Daje::Model::OrderHead;
use Daje::Model::OrderItem;
use Daje::Model::OrderCompanies;
use Daje::Model::OrderAddresses;
use Daje::Model::Companies;
use Daje::Order::Summary;;

use Try::Tiny;

has 'pg';

sub get_order_companies_fkey{
    my ($self, $order_head_pkey) = @_;

    return Daje::Model::OrderHead->new(
        pg => $self->pg
    )->companies_fkey(
        $order_head_pkey
    );
}

sub get_order_summary{
    my ($self, $order_head_pkey) = @_;

    return Daje::Order::Summary->new(
        pg => $self->pg
    )->get_summary(
        $order_head_pkey
    );
}

sub loadOpenOrderList{
    my ($self, $companies_fkey, $ordertype, $grid_fields_list) = @_;

    my $order->{data} = Daje::Model::OrderHead->new(
        pg => $self->pg
    )->loadOpenOrderList($companies_fkey, $ordertype, $grid_fields_list);
    return $order;
}

sub set_setdefault_item_data{
    my ($self, $data) = @_;

    return Daje::Model::OrderItem->new(
        pg => $self->pg
    )->set_setdefault_data($data);
}

sub load_order_head{
    my ($self, $order_head_pkey) = @_;

    return Daje::Model::OrderHead->new(
        pg => $self->pg
    )->load_order_head($order_head_pkey)
}

sub load_order_head_p{
    my ($self, $order_head_pkey) = @_;

    return Daje::Model::OrderHead->new(
        pg => $self->pg
    )->load_order_head_p($order_head_pkey)
}

sub load_order_items_p{
    my ($self, $order_head_pkey) = @_;

    return Daje::Model::OrderItem->new(
        pg => $self->pg
    )->load_order_items_p($order_head_pkey);
}

sub load_order_companies_p{
    my ($self, $order_head_pkey) = @_;

    return Daje::Model::OrderCompanies->new(
        pg => $self->pg
    )->load_order_companies_p($order_head_pkey);
}

sub load_order_addresses_p{
    my ($self, $order_head_pkey) = @_;

    return Daje::Model::OrderAddresses->new(
        pg => $self->pg
    )->load_order_addresses_p($order_head_pkey);
}

sub get_table_column_names{
    my $self = shift;

    my $ordercompanies = try {
        Daje::Model::Companies->new(
            pg => $self->pg
        )->get_table_column_names();
    }catch{
        $self->capture_message("[Daje::Order::Order::get_table_column_names Companies] " . $_);
        say $_;
    };

    my $orderaddresses = try{
        Daje::Model::OrderAddresses->new(
            pg => $self->pg
        )->get_table_column_names();
    }catch{
        $self->capture_message("[Daje::Order::Order::get_table_column_names OrderAddresses] " . $_);
        say $_;
    };

    my $orderhead = try{
        Daje::Model::OrderHead->new(
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
        ($data, $fields) = Daje::Model::Companies->new(
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
        ($data, $fields) = Daje::Model::OrderAddresses->new(
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
        ($data, $fields) = Daje::Model::OrderHead->new(
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