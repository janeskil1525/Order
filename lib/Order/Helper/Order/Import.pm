package Order::Helper::Order::Import;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::JSON qw {decode_json };

use Order::Model::SalesOrderHead;
use Order::Model::SalesOrderItem;
use Order::Model::PurchaseOrderHead;
use Order::Model::PurchaseOrderItem;
use Data::Dumper;

has 'pg';

sub importBasket{
	my ($self, $basket) = @_;

	#"1. Purchaseorder / Salesorder";
	#"1.1 Loop through items and create header if nessesary than save item";

	my $result->{success} = 1;
	my @suppliers;
	my $items;
    #$basket->{data} = $basket->{data}->to_array;
	@{$items} =  sort { $b->{company} cmp $a->{company} } @{$basket->{data}};
	my $purchaseorder_head_pkey;
	my $salesorder_head_pkey;

	eval {
		my $db = $self->pg->db;
		my $tx = $db->begin;

		for my $item (@{$items}){
			my %params = map { $_ => $item->{supplier}  } @suppliers;
			if (!( exists $params{$item->{supplier}})) {
				$basket->{order_no} = 0;
				$salesorder_head_pkey = Order::Model::SalesOrderHead->new(
					db => $db
				)->upsertHead($basket, 2, $item);

				$basket->{order_no} = 0;
				$purchaseorder_head_pkey = Order::Model::PurchaseOrderHead->new(
					db => $db
				)->upsertHead($basket, 1, $item);
				push @suppliers, $item->{supplier};
				push @{$result->{salesorder_head_pkey}}, $salesorder_head_pkey;
				push @{$result->{purchaseorder_head_pkey}}, $purchaseorder_head_pkey;
			}
			Order::Model::PurchaseOrderItem->new(
					db => $db
			)->upsertItem(
				$item, $purchaseorder_head_pkey
			);
			Order::Model::SalesOrderItem->new(
					db => $db
			)->upsertItem(
				$item, $salesorder_head_pkey
			);
		}
		$tx->commit();
	};
	# Daje::Utils::Sentinelsender->new()->capture_message("[Shoppingcart::Cart::importBasket] " . $@) if $@;
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
