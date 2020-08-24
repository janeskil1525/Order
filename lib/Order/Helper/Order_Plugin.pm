package Order::Helper::Order_Plugin;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::JSON qw {decode_json encode_json};

use Order::Helper::Order::Purchaseorder;
use Order::Helper::Order::Salesorder;
use Daje::Order::Import;
use Daje::Order::Order;
use Try::Tiny;
use Data::Dumper;

has 'pg';



sub getOpenPoList{
	my($self, $token) = @_;
  
	return Daje::Order::Purchaseorder->new(
		pg => $self->pg
	)->getOpenPoList($token);
}

sub getOpenSoList{
	my($self, $token) = @_;

	return Daje::Order::Salesorder->new(
		pg => $self->pg
	)->getOpenSoList($token);
}

sub set_setdefault_item_data{
	my($self, $data) = @_;

	return Daje::Order::Order->new(
		pg => $self->pg
	)->set_setdefault_item_data($data);
}

sub load_order_head_p{
	my ($self, $order_head_pkey) = @_;

	return Daje::Order::Order->new(
		pg => $self->pg
	)->load_order_head_p($order_head_pkey)
}

sub load_order_items_p{
	my ($self, $order_head_pkey) = @_;

	return Daje::Order::Order->new(
		pg => $self->pg
	)->load_order_items_p($order_head_pkey)
}

sub load_order_companies_p{
	my ($self, $order_head_pkey) = @_;

	return Daje::Order::Order->new(
		pg => $self->pg
	)->load_order_companies_p($order_head_pkey)
}

sub load_order_addresses_p{
	my ($self, $order_head_pkey) = @_;

	return Daje::Order::Order->new(
		pg => $self->pg
	)->load_order_addresses_p($order_head_pkey)
}

sub get_table_column_names{
	my $self = shift;

	return Daje::Order::Order->new(
		pg => $self->pg
	)->get_table_column_names();
}

sub get_table_default_data{
	my $self = shift;

	return Daje::Order::Order->new(
		pg => $self->pg
	)->get_table_default_data();
}
1;



__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Order - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Order');

  # Mojolicious::Lite
  plugin 'Order';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Order> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Order> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
