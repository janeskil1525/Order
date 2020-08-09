package Order::Helper::Shoppingcart;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::JSON qw {decode_json encode_json};
use Shoppingcart::Cart;
use Daje::Utils::Settings;
use Data::Dumper;
#use Daje::Orion::Interface;

our $VERSION = '0.45.1';

has 'pg';
has 'minion';
has 'config';

sub register {
	my ($self, $app, $conf) = @_;

	$self->pg($conf->{pg});
	$self->minion($app->minion);
	$self->config($app->config);

	$app->helper(shoppingcart => sub {$self});
}

sub getOpenBasketId{
	my ($self, $users_pkey) = @_;

	my $cart = Shoppingcart::Cart->new(pg => $self->pg);

	return $cart->getOpenBasketId($users_pkey);
}

sub openBasket{
	my ($self, $token) = @_;
	
	my $cart = Shoppingcart::Cart->new(pg => $self->pg);
	
	return $cart->openBasket($token);
}

sub dropBasket{
	my ($self, $basketid) = @_;
	 
	my $cart = Shoppingcart::Cart->new(pg => $self->pg);	
    my $result = $cart->dropBasket($basketid);
	
	return $result;
}

sub loadBasket{
	my ($self, $basketid, $token) = @_;
	
	my $settings = Daje::Utils::Settings->new(pg => $self->pg);
	my $grid_fields_list = $settings->get_settings_list('Basket_grid_fields', $token);
	my $details_fields_list = $settings->get_settings_list('Basket_details_fields', $token);
	my $address_fields_list = $settings->get_settings_list('Basket_address_fields', $token);
	my $cart = Shoppingcart::Cart->new(pg => $self->pg);	
    my $result = $cart->loadBasket($basketid, $grid_fields_list, $details_fields_list, $address_fields_list);
	
	return $result;
}

sub upsertItem{
    my ($self, $item) = @_;
	
    my $data = decode_json($item);
    
	my $cart = Shoppingcart::Cart->new(
		pg     => $self->pg,
	);
    my $result = $cart->upsertItem($data);
	return $result;
}

sub saveBasket{
    my ($self, $item) = @_;
	
    my $data = decode_json($item);
    
	my $cart = Shoppingcart::Cart->new(
		pg => $self->pg,
		);
    my $result = $cart->saveBasket($data);
   
	return $result;
}

sub checkOut{
    my ($self, $item) = @_;
	
    my $data = decode_json($item);
    
	my $cart = Shoppingcart::Cart->new(
		pg => $self->pg,
		);
    my $result = $cart->saveBasket($data, 1);
    my $json_result = encode_json($result);
	$self->minion->enqueue('create_orders' => [$json_result] => {priority => 0});
	
	return $result;
}

sub loadBasketFull{
    my($self, $basketid) = @_;
	
	my $cart = Shoppingcart::Cart->new(
		pg => $self->pg,
		);
    my $result = $cart->loadBasketFull($basketid);
	
	return $result;
}

sub list_basket_items_itemtype_p{
	my($self, $itemtype, $token) = @_;

	return Shoppingcart::Item->new(
		pg => $self->pg,
	)->list_basket_items_itemtype_p($itemtype, $token);

}
sub basket_items_load_p{
	my($self, $basket_item_pkey) = @_;

	return Shoppingcart::Item->new(
		pg => $self->pg,
	)->basket_items_load_p($basket_item_pkey);
}

sub set_setdefault_item_data{
	my($self, $data) = @_;

	return Daje::Order::Order->new(
		pg => $self->pg
	)->set_setdefault_item_data($data);
}

sub setStatusOrder{
    my($self, $basketid) = @_;
    
    my $cart = Shoppingcart::Cart->new(
		pg => $self->pg,
		)->setStatusOrder($basketid);
}
1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Basket - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Basket');

  # Mojolicious::Lite
  plugin 'Basket';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Basket> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Basket> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
