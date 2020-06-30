package Daje::Order::Import;
use Mojo::Base 'Daje::Utils::Sentry::Raven';

use Mojo::JSON qw {decode_json };

use Daje::Model::OrderHead;
use Daje::Model::OrderItem;
use Daje::Utils::Sentry::Raven;
use Data::Dumper;

has 'pg';

sub importBasket{
	my ($self, $basket) = @_;

	#"1. Purchaseorder / Salesorder";
	#"1.1 Loop through items and create header if nessesary than save item";

	my $result->{success} = 1;
	my @supplier_pkeys;	
	my $items;
    #$basket->{data} = $basket->{data}->to_array;
	@{$items} =  sort { $b->{supplier_fkey} <=> $a->{supplier_fkey} } @{$basket->{data}};
	my $purchaseorder_head_pkey;
	my $salesorder_head_pkey;

	eval {
		my $tx = $self->pg->db->begin;
		for my $item (@{$items}){
			my %params = map { $_ => $item->{supplier_fkey}  } @supplier_pkeys;
			if (!( exists $params{$item->{supplier_fkey}})) {
				$basket->{order_no} = 0;
				$purchaseorder_head_pkey = Daje::Model::OrderHead->new(
					pg => $self->pg
				)->upsertHead($basket, 1, $item->{supplier_fkey});

				$basket->{order_no} = 0;
				$salesorder_head_pkey = Daje::Model::OrderHead->new(
					pg => $self->pg
				)->upsertHead($basket, 2, $item->{supplier_fkey});
				push @supplier_pkeys, $item->{supplier_fkey};
				push @{$result->{salesorder_head_pkey}}, $salesorder_head_pkey;
				push @{$result->{purchaseorder_head_pkey}}, $purchaseorder_head_pkey;
			}
			Daje::Model::OrderItem->new(
					pg => $self->pg
			)->upsertItem(
				$item, $purchaseorder_head_pkey
			);
			Daje::Model::OrderItem->new(
					pg => $self->pg
			)->upsertItem(
				$item, $salesorder_head_pkey
			);
		}
		$tx->commit();
	};
	# Daje::Utils::Sentry::Raven->new()->capture_message("[Shoppingcart::Cart::importBasket] " . $@) if $@;
	say $@ if $@;

	$result->{success} = 0 if $@;

	return $result;
}


sub upsertHead{
	my ($self, $data, $ordertype) = @_;
	
	return Daje::Model::OrderHead->new(
		pg => $self->pg
	)->upsertHead($data, $ordertype);
}


1;
