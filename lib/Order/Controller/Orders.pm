package Order::Controller::Orders;
use Mojo::Base 'Mojolicious::Controller';

use Daje::Utils::Sentinelsender;
use Mojo::Promise;
use Data::Dumper;

sub list_purchaseorders{
	my $self = shift;
	my $token = $self->req->headers->header('X-Token-Check');
	my $purchaseorders = $self->order->getOpenPoList($token);
	$self->render(json => $purchaseorders);
}


sub list_salesorders{
	my $self = shift;
	my $company = $self->param("company");
	my $token = $self->req->headers->header('X-Token-Check');
	my $salesorders = $self->order->getOpenSoList($company);
	$self->render(json => $salesorders);
}

sub list_rfqs{
	my $self = shift;
	my $token = $self->req->headers->header('X-Token-Check');
	my $rfqs = $self->order->getOpenRfqList($token);
	$self->render(json => $rfqs);
}

sub load_item_api{
	my $self = shift;

	my $token = $self->req->headers->header('X-Token-Check');
	my $validator = $self->validation;
	if($validator->required('order_items_pkey')) {
		$self->render_later;
		my $order_items_pkey = $self->param('order_items_pkey');
		$self->order->load_item_p($order_items_pkey)->then(sub{
			my $result = shift;

			my $field_list;
			my $item = $result->hash;
			$result->finish;
			($item, $field_list) = $self->order->set_setdefault_item_data($item);

			my $detail = Daje::Utils::Translations->new(
				pg => $self->pg
			)->details_headers(
				'order_item', $field_list, $item, 'swe');

			$item->{header_data} = $detail;

			$self->render(json => $item);
		})->catch(sub {
			my $err = shift;
			Daje::Utils::Sentinelsender->new()->capture_message('','WebsShop', (ref $self), (caller(0))[3], $err);
			my $item->{header_data} ='';
			$item->{error} = "Could not load Order_item";
			say $err;
			$self->render(json => $item);
		})->wait;
	}
}

sub load_sales_order_api{
	my $self = shift;

	my $token = $self->req->headers->header('X-Token-Check');
	my $validator = $self->validation;
	if($validator->required('orders_pkey')) {
		my $orders_pkey = $self->param('orders_pkey');
		my $fields_list = $self->settings->get_settings_list('Order_items_grid', $token);
		my $order->{order_items}->{headers} = $self->translations->grid_header(
			'Order_items_grid', $fields_list, 'swe'
		);

		if ($orders_pkey == 0) {

			my $table = $self->order->get_table_default_data();
			$order->{order_items}->{data} = [];

			$order->{header_data} = $self->translations->details_headers(
				'order_head', $table->{orderhead}->{fields},
				$table->{orderhead}->{data}, 'swe'
			);

			my $order_companies = $self->translations->details_headers(
				'companies', $table->{ordercompanies}->{fields},
				$table->{ordercompanies}->{data}, 'swe'
			);
			foreach my $key (keys(%{$order_companies})) {
				$order->{header_data}->{$key} = $order_companies->{$key};
			}

			my $order_addresses = $self->translations->details_headers(
				'order_addresses', $table->{orderaddresses}->{fields},
				$table->{orderaddresses}->{data}, 'swe'
			);
			foreach my $key (keys(%{$order_addresses})) {
				$order->{header_data}->{invoiceaddress}->{$key} = $order_addresses->{$key};
			}

			foreach my $key (keys(%{$order_addresses})) {
				$order->{header_data}->{deliveryaddress}->{$key} = $order_addresses->{$key};
			}

			$order->{error} = 'Success';

			$self->render(json => $order);
		}else{

			$self->render_later;

			my ($orderhead_fields, $orderaddresses_fields, $ordercompanies_fields) =
				$self->order->get_table_column_names();
			my $orderhead = $self->order->load_order_head_p($orders_pkey);
			my $orderitems = $self->order->load_order_items_p($orders_pkey, $fields_list);
			my $ordercompanies = $self->order->load_order_companies_p($orders_pkey);
			my $invoiceaddress = $self->order->load_order_addresses_p($orders_pkey,'Invoice');
			my $deliveryaddress = $self->order->load_order_addresses_p($orders_pkey,'Invoice');
			Mojo::Promise->all(($orderhead, $orderitems, $ordercompanies, $invoiceaddress, $deliveryaddress))->then(sub {
				my ($orderhead, $orderitems, $ordercompanies, $invoiceaddress, $deliveryaddress) = @_;


				$order->{order_items}->{data} = $orderitems->[0]->hashes;

				$order->{header_data} = $self->translations->details_headers(
					'order_head', $orderhead_fields, $orderhead->[0]->hash(), 'swe'
				);

				my $order_companies = $self->translations->details_headers(
					'companies', $ordercompanies_fields, $ordercompanies->[0]->hash(), 'swe'
				);
				foreach my $key (keys(%{$order_companies})) {
					$order->{header_data}->{$key} = $order_companies->{$key};
				}

				my $invoice_addresses = $self->translations->details_headers(
					'order_addresses', $orderaddresses_fields, $invoiceaddress->[0]->hash(), 'swe'
				);
				foreach my $key (keys(%{$invoice_addresses})) {
					$order->{header_data}->{invoiceaddress}->{$key} = $invoice_addresses->{$key};
				}

				my $delivery_addresses = $self->translations->details_headers(
					'order_addresses', $orderaddresses_fields, $deliveryaddress->[0]->hash(), 'swe'
				);
				foreach my $key (keys(%{$delivery_addresses})) {
					$order->{header_data}->{deliveryaddress}->{$key} = $delivery_addresses->{$key};
				}

				$order->{error} = 'Success';

				$self->render(json => $order);

			})->catch(sub {
				my $err = shift;
				Daje::Utils::Sentinelsender->new()->capture_message('','WebsShop', (ref $self), (caller(0))[3], $err);
				my $order->{header_data} = '';
				$order->{error} = $err;
				say $err;
				$self->render(json => $order);
			})->wait;
		}

	}
}

sub load_purchase_order_api{
	my $self = shift;

	my $token = $self->req->headers->header('X-Token-Check');
	my $validator = $self->validation;
	if($validator->required('orders_pkey')) {
		my $orders_pkey = $self->param('orders_pkey');
		my $ordertype = $self->param('ordertype');

		my $fields_list = $self->settings->get_settings_list('Order_items_grid', $token);
		my $order->{order_items}->{headers} = $self->translations->grid_header(
			'Order_items_grid', $fields_list, 'swe'
		);

		if ($orders_pkey == 0) {

			my $table = $self->order->get_table_default_data();
			$order->{order_items}->{data} = [];

			$order->{header_data} = $self->translations->details_headers(
				'order_head', $table->{orderhead}->{fields},
				$table->{orderhead}->{data}, 'swe'
			);

			my $order_companies = $self->translations->details_headers(
				'companies', $table->{ordercompanies}->{fields},
				$table->{ordercompanies}->{data}, 'swe'
			);
			foreach my $key (keys(%{$order_companies})) {
				$order->{header_data}->{$key} = $order_companies->{$key};
			}

			my $order_addresses = $self->translations->details_headers(
				'order_addresses', $table->{orderaddresses}->{fields},
				$table->{orderaddresses}->{data}, 'swe'
			);
			foreach my $key (keys(%{$order_addresses})) {
				$order->{header_data}->{$key} = $order_addresses->{$key};
			}

			$order->{error} = 'Success';

			$self->render(json => $order);
		}else{

			$self->render_later;

			my ($orderhead_fields, $orderaddresses_fields, $ordercompanies_fields) =
				$self->order->get_table_column_names();
			my $orderhead = $self->order->load_order_head_p($orders_pkey);
			my $orderitems = $self->order->load_order_items_p($orders_pkey, $fields_list);
			my $ordercompanies = $self->order->load_order_companies_p($orders_pkey);
			my $orderaddresses = $self->order->load_order_addresses_p($orders_pkey, 'Supplier');
			Mojo::Promise->all(($orderhead, $orderitems, $ordercompanies, $orderaddresses))->then(sub {
				my ($orderhead, $orderitems, $ordercompanies, $orderaddresses) = @_;


				$order->{order_items}->{data} = $orderitems->[0]->hashes;

				$order->{header_data} = $self->translations->details_headers(
					'order_head', $orderhead_fields, $orderhead->[0]->hash(), 'swe'
				);

				my $order_companies = $self->translations->details_headers(
					'companies', $ordercompanies_fields, $ordercompanies->[0]->hash(), 'swe'
				);
				foreach my $key (keys(%{$order_companies})) {
					$order->{header_data}->{$key} = $order_companies->{$key};
				}

				my $order_addresses = $self->translations->details_headers(
					'order_addresses', $orderaddresses_fields, $orderaddresses->[0]->hash(), 'swe'
				);
				foreach my $key (keys(%{$order_addresses})) {
					$order->{header_data}->{$key} = $order_addresses->{$key};
				}

				$order->{error} = 'Success';

				$self->render(json => $order);

			})->catch(sub {
				my $err = shift;
				Daje::Utils::Sentinelsender->new()->capture_message('','WebsShop', (ref $self), (caller(0))[3], $err);
				my $order->{header_data} = '';
				$order->{error} = $err;
				say $err;
				$self->render(json => $order);
			})->wait;
		}
	}
}
1;

1;