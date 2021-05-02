package Order::Controller::Orders;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Daje::Utils::Sentinelsender;
use Mojo::Promise;
use Data::Dumper;

sub list_purchaseorders ($self) {

    my $company = $self->param("company");
	my $purchaseorders = $self->purchaseorder->getOpenPoList($company);
	$self->render(json => $purchaseorders);
}


sub list_salesorders ($self) {

	my $company = $self->param("company");
	my $salesorders = $self->salesorder->getOpenSoList($company);
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

			my $detail = $self-translations->details_headers(
				'order_item', $field_list, $item, 'swe'
			);

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
	if($validator->required('sales_order_head_pkey')) {
		my $orders_pkey = $self->param('sales_order_head_pkey');

		my $order = $self->salesorder->load_sales_order($orders_pkey);

		$self->render(json => $order);

	} else {
		$self->render(json => {error => 'sales_order_head_pkey is missing'});
	}

}

sub load_purchase_order_api{
	my $self = shift;

    my $order;
	my $validator = $self->validation;
	if($validator->required('purchase_order_head_pkey')) {
		my $orders_pkey = $self->param('purchase_order_head_pkey');

        $order = $self->purchaseorder->load_purchase_order_api($orders_pkey);
        $self->render(json => $order);
    } else {
        $self->render(json => {error => 'purchase_order_head_pkey is missing'});
    }
}

1;