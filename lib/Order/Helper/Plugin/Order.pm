package Mojolicious::Plugin::Order;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::JSON qw {decode_json encode_json};
use Daje::Utils::Sentry::Raven;
use Daje::Order::Purchaseorder;
use Daje::Order::Salesorder;
use Daje::Order::Import;
use Daje::Order::Order;
use Try::Tiny;
use Data::Dumper;

our $VERSION = '0.11';

has 'pg';

sub register {
  my ($self, $app, $conf) = @_;
	
	$self->pg($conf->{pg});
	
	$app->minion->add_task(create_orders => \&_create_orders);

	#$app->pg->migrations->name('order')->from_data('Mojolicious::Plugin::Order', 'order.sql')->migrate(1);
	$app->helper(order => sub {$self});
}

sub _create_orders{
	my($job, $import) = @_;

	my $salesorder_notice = Daje::Messages::Notice->new(pg => $job->app->pg);
	my $purchaseorder_notice = Daje::Messages::Notice->new(pg => $job->app->pg);

	my $data = decode_json $import;
	my $basket = $job->app->shoppingcart->loadBasketFull($data->{basketid});
	my $order = Daje::Order::Import->new(pg => $job->app->pg)->importBasket($basket);
	my $summary = Daje::Order::Order->new(pg => $job->app->pg);
    if($order->{success}){
        $job->app->shoppingcart->setStatusOrder($data->{basketid});


		$salesorder_notice->title('Kundorder');
		my $length = scalar @{$order->{salesorder_head_pkey}};
		try{
			for(my $i = 0; $i < $length; $i++){
				$salesorder_notice->subtitle('Kundorder');
				$salesorder_notice->companies_fkey(
					$summary->get_order_companies_fkey(
						@{$order->{salesorder_head_pkey}}[$i]
					)
				);
				$salesorder_notice->message(
					$summary->get_order_summary(
						@{$order->{salesorder_head_pkey}}[$i]
					)
				);

				my $message_hash = $salesorder_notice->get_payload();
				my $salesorder_json = encode_json($message_hash);
				$job->app->minion->enqueue('create_message' => [$salesorder_json] );
			}
		}catch{
			Daje::Utils::Sentry::Raven->new()->capture_message(
				"[DMojolicious::Plugin::Order::_create_orders] salesorder_head_pkey " . $_
			);
			say "[DMojolicious::Plugin::Order::_create_orders] salesorder_head_pkey " . $_;
		};


		$purchaseorder_notice->title('Inköpsorder');
		$length = scalar @{$order->{purchaseorder_head_pkey}};
		try{
			for(my $i = 0; $i < $length; $i++){

				$purchaseorder_notice->subtitle('Inköpsorder');

				$purchaseorder_notice->companies_fkey($summary->get_order_companies_fkey(
					@{$order->{purchaseorder_head_pkey}}[$i]
				));
				$purchaseorder_notice->message(
					$summary->get_order_summary(
						@{$order->{purchaseorder_head_pkey}}[$i]
					)
				);

				my $message_hash = $purchaseorder_notice->get_payload();
				my $purchaseorder_json = encode_json($message_hash);
				$job->app->minion->enqueue('create_message' => [$purchaseorder_json] );
			}
		}catch{
			Daje::Utils::Sentry::Raven->new()->capture_message(
				"[DMojolicious::Plugin::Order::_create_orders] purchaseorder_head_pkey " . $_
			);
			say "[DMojolicious::Plugin::Order::_create_orders] purchaseorder_head_pkey " . $_;
		};

		$job->finish({ status => 'success'});
    }else{
		$job->finish({ status => 'failed'});
	}

}

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
