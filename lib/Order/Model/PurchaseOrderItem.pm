package Order::Model::PurchaseOrderItem;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Utils::Postgres::Columns;
use Mojo::JSON qw {decode_json };
use Try::Tiny;

has 'pg';
has 'db';

sub load_order_items_p{
	my ($self, $order_head_pkey) = @_;

	return $self->pg->db->select_p(
		'order_items', '*',
		{
			order_head_fkey => $order_head_pkey
		});
}


sub upsertItem{
	my ($self, $data, $purchase_order_head_pkey) = @_;

	my $db;
	if($self->db) {
		$db = $self->db;
	} else {
		$db = $self->pg->db;
	}
	$data->{freight} = 0 unless $data->{freight};
	$data->{discount} = 0 unless $data->{discount};
	$data->{description} = '' unless $data->{description};
	
	my $result = try {
		$db->insert(
			'purchase_order_items',
				{
					purchase_order_head_fkey => $purchase_order_head_pkey,
					itemno => $data->{itemno},
					stockitem => $data->{stockitem},
					description => $data->{description},
					quantity => $data->{quantity},
					price => $data->{price},
					freight => $data->{freight},
					discount => $data->{discount},
				},
				{
					on_conflict => \[
						'(purchase_order_head_fkey, itemno) Do update set moddatetime = ?', 'now()'],
					returning => 'purchase_order_items_pkey'
				}
		)->hash;
	}catch{
		$self->capture_message("[Daje::Model::OrderItem::upsertItem] " . $_);
		say $_;
	};
	
	return $result;
}

sub set_setdefault_data{
	my ($self, $data) = @_;

	my $fields;
	($data, $fields) = Order::Utils::Postgres::Columns->new(
		pg => $self->pg
	)->set_setdefault_data($data, 'order_items');

	return $data, $fields;
}

sub get_table_column_names {
	my $self = shift;

	my $fields;
	$fields = Order::Utils::Postgres::Columns->new(
		pg => $self->pg
	)->get_table_column_names('order_items');

	return $fields;
}
1;
