package Shoppingcart::Item;
use Mojo::Base "Daje::Utils::Sentinelsender";

use Daje::Model::Data::Reservation;
use Daje::Warehouse::Stockmanager;
use Daje::Utils::Postgres::Columns;
use Data::Dumper;

has 'pg';


sub dropItems{
	my ($self, $basket_pkey) = @_;
	
	$self->pg->db->delete('basket_item',{basket_fkey => $basket_pkey});
	
	return 1;
}

sub getItems{
	my ($self, $basket_pkey, $gridfields) = @_;
	
	return $self->pg->db->select('basket_item',$gridfields, {
		basket_fkey => $basket_pkey,
		quantity    => {'>' => 0},
	})->hashes;
}

sub upsertItem{
	my ($self, $data) = @_;

	$data->{rfq_note} = '' unless $data->{rfq_note};
	$data->{itemno} = $self->pg->db->query(
		qq{SELECT COALESCE(MAX(itemno), 0) + 1  as itemno FROM basket_item WHERE basket_fkey = ? },
			$data->{basket_pkey})->hash->{itemno}
	unless $data->{itemno};

	my $result = $self->pg->db->insert(
		'basket_item', {
			basket_fkey => $data->{basket_pkey},
			stockitem => $data->{stockitem},
			quantity => $data->{quantity},
			itemno => $data->{itemno},
			price => $data->{price},
			description => $data->{description},
			supplier_fkey => $data->{supplier_fkey},
			stockitems_fkey => $data->{stockitems_fkey},
			freight => $data->{freight},
			rfq_note => $data->{rfq_note}},
			{
				on_conflict => \[
					'(basket_fkey, itemno) do update set quantity = ?, rfq_note = ?, freight = ?',
						($data->{quantity}, $data->{rfq_note}, $data->{freight})
				],
				returning   => 'basket_item_pkey',
			}
		)->hash;

	if(exists $data->{stockitems_fkey} and $data->{stockitems_fkey} > 0){
		my $reservation = Daje::Model::Data::Reservation->new(
			stockitems_pkey       => $data->{stockitems_fkey},
			quantity              => $data->{quantity} * -1,
			reservation_type      => 1,
			reservation_reference => $data->{description},
			companies_pkey        => $data->{supplier_fkey},
			source_fkey           => $result->{basket_item_pkey},
		);

		if($data->{quantity} == 0){
			Daje::Warehouse::Stockmanager->new(
				pg => $self->pg
			)->delete_reservation($reservation);
		}else{
			Daje::Warehouse::Stockmanager->new(
				pg => $self->pg
			)->add_reservation($reservation);
		}
	}

	return $result;
}

sub list_basket_items_itemtype_p{
	my($self, $itemtype, $token) = @_;

	return $self->pg->db->query_p(
		qq{ SELECT
				basket_item_pkey, basket_fkey, itemtype, itemno, stockitem, description, quantity, price,
				externalref, expirydate, supplier_fkey, rfq_note, stockitems_fkey
			FROM basket_item WHERE itemtype = ?
			AND basket_fkey IN (
				SELECT basket_pkey FROM basket
				WHERE companies_fkey = (select get_company_fkey(?)) AND approved = false
			)},($itemtype, $token)
	);
}

sub basket_items_load_p{
	my($self, $basket_item_pkey) = @_;

	return $self->pg->db->select_p( 'basket_item','*',  {basket_item_pkey => $basket_item_pkey});
}

sub set_setdefault_data{
	my ($self, $data) = @_;

	my $fields;
	($data, $fields) = Daje::Utils::Postgres::Columns->new(
		pg => $self->pg
	)->set_setdefault_data($data, 'basket_item');

	return $data, $fields;
}
1;
