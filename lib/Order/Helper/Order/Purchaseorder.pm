package Order::Helper::Order::Purchaseorder;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::JSON qw {decode_json };

use Daje::Utils::Settings;
use Daje::Model::User;
use Daje::Order::Order;
use Daje::Utils::Translations;


has 'translations';
has 'settings';
has 'pg';

sub getOpenPoList{
	my($self, $token) = @_;
	
	my $settings = Daje::Utils::Settings->new(pg => $self->pg);
	my $user = Daje::Model::User->new(pg => $self->pg);
	my $companies_fkey = $user->get_company_fkey_from_token($token);
	my $order = Daje::Order::Order->new(pg => $self->pg);
	my $grid_fields_list = $settings->get_settings_list('Purchaseorder_grid_fields', $token);
	
	my $purchaseorder = $order->loadOpenOrderList($companies_fkey->{companies_fkey}, 1, $grid_fields_list);
	my $transtation = Daje::Utils::Translations->new(pg => $self->pg);
	$purchaseorder->{headers} =  $transtation->grid_header('Purchaseorder_grid_fields', $grid_fields_list,'swe');
	
	return $purchaseorder;
}

#$self->pg->migrations->name('basket')->from_data('Mojolicious::Plugin::Shoppingcart', 'basket.sql')->migrate(1);
1;

