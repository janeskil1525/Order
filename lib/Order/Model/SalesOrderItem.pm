package Order::Model::SalesOrderItem;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Daje::Utils::Postgres::Columns;
use Mojo::JSON qw {decode_json };
use Try::Tiny;

has 'pg';
has 'db';

sub load_order_items_p{
	my ($self, $sales_order_head_pkey) = @_;

	return $self->pg->db->select_p(
		'sales_order_items', '*',
		{
			sales_order_head_fkey => $sales_order_head_pkey
		});
}


sub upsertItem{
	my ($self, $data, $sales_order_head_pkey) = @_;

	my $db;
	if($self->db) {
		$db = $self->db;
	} else {
		$db = $self->pg->db;
	}

	$data->{description} = '' unless $data->{description};
	
	my $result = try {
		$db->insert('sales_order_items',
			{
				sales_order_head_fkey => $sales_order_head_pkey,
					itemno => $data->{itemno},
					stockitem => $data->{stockitem},
					description => $data->{description},
					quantity => $data->{quantity},
					price => $data->{price},
				},
				{
					on_conflict => \[
						'(sales_order_head_fkey, itemno) Do update set moddatetime = ?', 'now()'],
					returning => 'sales_order_items_pkey'
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
	($data, $fields) = Daje::Utils::Postgres::Columns->new(
		pg => $self->pg
	)->set_setdefault_data($data, 'sales_order_items');

	return $data, $fields;
}

sub get_table_column_names {
	my $self = shift;

	my $fields;
	$fields = Daje::Utils::Postgres::Columns->new(
		pg => $self->pg
	)->get_table_column_names('sales_order_items');

	return $fields;
}
1;
