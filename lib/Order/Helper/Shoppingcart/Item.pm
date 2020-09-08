package Order::Helper::Shoppingcart::Item;
use Mojo::Base "Daje::Utils::Sentinelsender";

#use Daje::Model::Data::Reservation;
#use Daje::Warehouse::Stockmanager;
use Order::Utils::Postgres::Columns;
use Data::Dumper;
use Try::Tiny;

has 'pg';
has 'db';


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

sub getItemsFull {
	my ($self, $basket_pkey) = @_;

	my $result = try {
			$self->pg->db->query(
			qq{
				SELECT
					itemtype, itemno, stockitem, description, quantity, price, freight
					suppliers_pkey, company, name, registrationnumber, phone, homepage, address1, address2, address3,
					zipcode, city, company_mails, sales_mails, suppliers_pkey, company as supplier
				FROM basket_item, suppliers
				WHERE basket_item_fkey = basket_item_pkey AND quantity > 0 and basket_fkey = ?
			},
			($basket_pkey)
		)->hashes;
	} catch {
		say $_;
		$self->capture_message('','Order::Helper::Shoppingcart::Item::getItemsFull', (ref $self), (caller(0))[3], $_);
	};

	return $result;

}
sub upsertItem{
	my ($self, $data) = @_;

	my $db;
	if ($self->db){
		$db = $self->db;
	} else {
		$db = $self->pg->db;
	}
	$data->{rfq_note} = '' unless $data->{rfq_note};
	$data->{itemno} = $db->query(
		qq{SELECT COALESCE(MAX(itemno), 0) + 1  as itemno FROM basket_item WHERE basket_fkey = ? },
			$data->{basket_pkey})->hash->{itemno}
		unless $data->{itemno};

	my $result = $db->insert(
		'basket_item', {
			basket_fkey => $data->{basket_pkey},
			stockitem => $data->{stockitem},
			quantity => $data->{quantity},
			itemno => $data->{itemno},
			price => $data->{price},
			description => $data->{description},
			supplier => $data->{supplier}->{company}->{company},
			externalref => $data->{stockitems_fkey},
			freight => $data->{freight},
			rfq_note => $data->{rfq_note}},
			{
				on_conflict => \[
					'(basket_fkey, stockitem) do update set quantity = ?, rfq_note = ?, freight = ?',
						($data->{quantity}, $data->{rfq_note}, $data->{freight})
				],
				returning   => 'basket_item_pkey',
			}
		)->hash;

	$db->insert('suppliers',
		{
			company => $data->{supplier}->{company}->{company},
			name => $data->{supplier}->{company}->{name},
			registrationnumber => $data->{supplier}->{company}->{registrationnumber},
			phone => $data->{supplier}->{company}->{phone},
			homepage => $data->{supplier}->{company}->{homepage},
			address1 => $data->{supplier}->{address}->{address1},
			address2 => $data->{supplier}->{address}->{address2},
			address3 => $data->{supplier}->{address}->{address3},
			zipcode => $data->{supplier}->{address}->{zipcode},
			city => $data->{supplier}->{address}->{city},
			company_mails => $data->{supplier}->{company_mails},
			sales_mails => $data->{supplier}->{sales_mails},
			basket_item_fkey  => $result->{basket_item_pkey},
		},
		 {
		 	on_conflict => [
				['basket_item_fkey'] => {
		 			moddatetime => 'now()',
		 			company => $data->{supplier}->{company}->{company},
		 			name => $data->{supplier}->{company}->{name},
					registrationnumber => $data->{supplier}->{company}->{registrationnumber},
		 			phone => $data->{supplier}->{company}->{phone},
		 			homepage => $data->{supplier}->{company}->{homepage},
					address1 => $data->{supplier}->{address}->{address1},
					address2 => $data->{supplier}->{address}->{address2},
					address3 => $data->{supplier}->{address}->{address3},
					zipcode => $data->{supplier}->{address}->{zipcode},
					city => $data->{supplier}->{address}->{city},
					company_mails => $data->{supplier}->{company_mails},
		 			sales_mails => $data->{supplier}->{sales_mails},,
		 		}
			]
		 }
	);

	# if(exists $data->{stockitems_fkey} and $data->{stockitems_fkey} > 0){
	# 	my $reservation = Daje::Model::Data::Reservation->new(
	# 		stockitems_pkey       => $data->{stockitems_fkey},
	# 		quantity              => $data->{quantity} * -1,
	# 		reservation_type      => 1,
	# 		reservation_reference => $data->{description},
	# 		companies_pkey        => $data->{supplier_fkey},
	# 		source_fkey           => $result->{basket_item_pkey},
	# 	);
	#
	# 	if($data->{quantity} == 0){
	# 		Daje::Warehouse::Stockmanager->new(
	# 			pg => $self->pg
	# 		)->delete_reservation($reservation);
	# 	}else{
	# 		Daje::Warehouse::Stockmanager->new(
	# 			pg => $self->pg
	# 		)->add_reservation($reservation);
	# 	}
	# }

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
	($data, $fields) = Order::Utils::Postgres::Columns->new(
		pg => $self->pg
	)->set_setdefault_data($data, 'basket_item');

	return $data, $fields;
}
1;
