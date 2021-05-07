package Order::Helper::Order::Export;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Order::Model::SalesOrderHead;
use Order::Model::SalesorderAdresses;
use Order::Model::SalesOrderItem;

has 'pg';

async sub export_orders ($self, $system) {

    my @orders;
    my $order_obj = Order::Model::SalesOrderHead->new(pg => $self->pg);
    my $order_list = await $order_obj->new(
        pg => $self->pg
    )->loadExportOrderList(
        $system
    );

    foreach my $order (@{$order_list}) {
        my $full_order;
        await $order_obj->set_export_status_async($order->{sales_order_head_pkey},'inprogress');
        my $orderitems = await Order::Model::SalesOrderItem->new(
            pg => $self->pg
        )->load_salesorder_items_async(
            $order->{sales_order_head_pkey}
        );

        $full_order->{head} = $order;
        $full_order->{items} = $orderitems;
        $full_order->{invoiceaddress} = await Order::Model::SalesorderAdresses->new(
            pg => $self->pg
        )->load_salesorder_addresses_async(
            $order->{sales_order_head_pkey},'Invoice'
        );
        $full_order->{deliveryaddress} = await Order::Model::SalesorderAdresses->new(
            pg => $self->pg
        )->load_salesorder_addresses_async(
            $order->{sales_order_head_pkey},'Delivery'
        );

        push @orders, $full_order;
        await $order_obj->set_export_status_async($order->{sales_order_head_pkey},'exported');
    }

    return \@orders;
}


1;