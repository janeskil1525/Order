package Order::Model::SalesOrderItem;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Utils::Postgres::Columns;
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
		}
	);
}

sub load_order_items {
	my ($self, $sales_order_head_pkey) = @_;

	my $result = $self->pg->db->select (
		'sales_order_items', '*',
		{
			sales_order_head_fkey => $sales_order_head_pkey
		}
	);

	my $hash;
	$hash = $result->hashes if $result->rows;

	return $hash;
}

sub upsertItem{
	my ($self, $data, $sales_order_head_pkey) = @_;

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
		$db->insert('sales_order_items',
			{
				sales_order_head_fkey => $sales_order_head_pkey,
				stockitem             => $data->{stockitem},
				description           => $data->{description},
				quantity              => $data->{quantity},
				price                 => $data->{price},
				freight               => $data->{freight},
				discount              => $data->{discount},
				extradata             => $data->{extradata},
				},
				{
					on_conflict => \[
						'(sales_order_head_fkey, stockitem) Do update set moddatetime = ?', 'now()'],
					returning => 'sales_order_items_pkey'
				}
			)->hash;
	}catch{
		say $_;
		$self->capture_message("[Daje::Model::OrderItem::upsertItem] " . $_);
	};
	
	return $result;
}

sub set_setdefault_data{
	my ($self, $data) = @_;

	my $fields;
	($data, $fields) = Order::Utils::Postgres::Columns->new(
		pg => $self->pg
	)->set_setdefault_data($data, 'sales_order_items');

	return $data, $fields;
}

sub get_table_column_names {
	my $self = shift;

	my $fields;
	$fields = Order::Utils::Postgres::Columns->new(
		pg => $self->pg
	)->get_table_column_names('sales_order_items');

	return $fields;
}
1;
