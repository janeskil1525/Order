package Order::Helper::Order::Salesorder;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Mojo::JSON qw {decode_json };
use Order::Model::SalesOrderHead;
use Data::Dumper;

has 'translations';
has 'settings';
has 'pg';

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

#$self->pg->migrations->name('basket')->from_data('Mojolicious::Plugin::Shoppingcart', 'basket.sql')->migrate(1);
1;
