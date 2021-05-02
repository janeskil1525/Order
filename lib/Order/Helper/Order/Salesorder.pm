package Order::Helper::Order::Salesorder;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Mojo::JSON qw {decode_json };
use Order::Model::SalesOrderHead;
use Order::Model::SalesOrderItem;
use Order::Model::SalesorderAdresses;
use Order::Helper::Postgres::Columns;

use Data::Dumper;

has 'translations';
has 'settings';
has 'pg';

sub load_sales_order ($self, $orders_pkey) {

	my $orderaddresses_fields =
		$self->get_table_column_names('purchase_order_addresses');

	my $fields_list = $self->settings->get_settings_list('Order_items_grid', 0,0);

	my $order->{order_items}->{headers} = $self->translations->grid_header(
		'Order_items_grid', $fields_list, 'swe'
	);

	if ($orders_pkey != 0) {

		my $orderhead_fields =
			$self->get_table_column_names('sales_order_head');

		my $setting->{setting_order} = 0;
		$setting->{setting_value} = 'valuesummary';
		push @{$orderhead_fields}, $setting;

		my $salesorder = Order::Model::SalesOrderHead->new(
			pg => $self->pg
		)->load_order_head(
			$orders_pkey
		);

		my $orderitems = Order::Model::SalesOrderItem->new(
			pg => $self->pg
		)->load_salesorder_items(
			$orders_pkey
		);
		$salesorder->{valuesummary} = 0;

		foreach my $item (@{$orderitems}) {
			$salesorder->{valuesummary} += $item->{price} * $item->{quantity};
		}

		my $invoiceaddress = Order::Model::SalesorderAdresses->new(
			pg => $self->pg
		)->load_salesorder_addresses($orders_pkey, 'Invoice');

		my $deliveryaddress = Order::Model::SalesorderAdresses->new(
			pg => $self->pg
		)->load_salesorder_addresses($orders_pkey,'Invoice');


		$order->{order_items}->{data} = $orderitems;

		$order->{header_data} = $self->translations->details_headers(
			'order_head', $orderhead_fields, $salesorder, 'swe'
		);

		# my $order_companies = $self->translations->details_headers(
		# 	'companies', $ordercompanies_fields, $ordercompanies->[0]->hash(), 'swe'
		# );
		# 	foreach my $key (keys(%{$order_companies})) {
		# 		$order->{header_data}->{$key} = $order_companies->{$key};
		# 	}

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

sub getOpenSoList ($self, $company) {

	my $grid_fields_list = $self->settings->get_settings_list('Salesorder_grid_fields');

	my $salesorders = Order::Model::SalesOrderHead->new(
		pg => $self->pg
	)->loadOpenOrderList(
		$company, $grid_fields_list
	);


	my $order->{headers} =  $self->translations->grid_header(
		'Salesorder_grid_fields', $grid_fields_list,'swe'
	);

	$order->{data} = $salesorders;
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
