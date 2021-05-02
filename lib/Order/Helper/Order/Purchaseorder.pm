package Order::Helper::Order::Purchaseorder;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures;

use Mojo::JSON qw {decode_json };

use Order::Model::PurchaseOrderHead;
use Order::Model::PurchaseorderAdresses;
use Order::Model::PurchaseOrderHead;
use Order::Model::PurchaseOrderItem;
use Data::Dumper;

has 'translations';
has 'settings';
has 'pg';

sub getOpenPoList ($self, $company) {

	my $grid_fields_list = $self->settings->get_settings_list('Purchaseorder_grid_fields', 0,0);
	
	my $purchaseorder = Order::Model::PurchaseOrderHead->new(
		pg => $self->pg
	)->loadOpenOrderList($company, $grid_fields_list);

	my $order->{headers} =  $self->translations->grid_header(
		'Purchaseorder_grid_fields', $grid_fields_list,'swe'
	);
	$order->{data} = $purchaseorder;
	return $order;
}

sub load_purchase_order_api ($self, $orders_pkey) {

	my $orderaddresses_fields =
		$self->get_table_column_names('purchase_order_addresses');

	my $fields_list = $self->settings->get_settings_list('Order_items_grid', 0,0);
	my $order->{order_items}->{headers} = $self->translations->grid_header(
		'Order_items_grid', $fields_list, 'swe'
	);

	if ($orders_pkey != 0) {

		my $orderhead_fields =
			$self->get_table_column_names('purchase_order_head');

		my $setting->{setting_order} = 0;
		$setting->{setting_value} = 'valuesummary';
		push @{$orderhead_fields}, $setting;

		my $orderhead = Order::Model::PurchaseOrderHead->new(
			pg => $self->pg
		)->load_order_head(
			$orders_pkey
		);

		my $orderitems = Order::Model::PurchaseOrderItem->new(
			pg => $self->pg
		)->load_order_items(
			$orders_pkey
		);
		$orderhead->{valuesummary} = 0;

		foreach my $item (@{$orderitems}) {
			$orderhead->{valuesummary} += $item->{price} * $item->{quantity};
		}

		my $invoiceaddress = Order::Model::PurchaseorderAdresses->new(
			pg => $self->pg
		)->load_purchase_order_addresses($orders_pkey, 'Invoice');

		my $deliveryaddress = Order::Model::PurchaseorderAdresses->new(
			pg => $self->pg
		)->load_purchase_order_addresses($orders_pkey,'Invoice');

		$order->{order_items}->{data} = $orderitems;

		$order->{header_data} = $self->translations->details_headers(
			'purchase_order_head', $orderhead_fields, $orderhead, 'swe'
		);

		my $invoice_addresses = $self->translations->details_headers(
			'order_addresses', $orderaddresses_fields, $invoiceaddress, 'swe'
		) if $invoiceaddress;

		foreach my $key (keys(%{$invoice_addresses})) {
			$order->{header_data}->{invoiceaddress}->{$key} = $invoice_addresses->{$key};
		}

		my $delivery_addresses = $self->translations->details_headers(
			'order_addresses', $orderaddresses_fields, $deliveryaddress, 'swe'
		) if $deliveryaddress;

		foreach my $key (keys(%{$delivery_addresses})) {
			$order->{header_data}->{deliveryaddress}->{$key} = $delivery_addresses->{$key};
		}

		$order->{error} = 'Success';
	}
	return $order;
}

sub get_table_column_names ($self, $table) {

	my $fields;
	$fields = Order::Helper::Postgres::Columns->new(
		pg => $self->pg
	)->get_table_column_names($table);

	return $fields;
}
#$self->pg->migrations->name('basket')->from_data('Mojolicious::Plugin::Shoppingcart', 'basket.sql')->migrate(1);
1;

