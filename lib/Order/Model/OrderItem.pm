package Daje::Model::OrderItem;
use Mojo::Base 'Daje::Utils::Sentry::Raven';

use Daje::Utils::Postgres::Columns;
use Mojo::JSON qw {decode_json };
use Try::Tiny;

has 'pg';

sub load_order_items_p{
	my ($self, $order_head_pkey) = @_;

	return $self->pg->db->select_p(
		'order_items', '*',
		{
			order_head_fkey => $order_head_pkey
		});
}


sub upsertItem{
	my ($self, $data, $order_head_pkey) = @_;
	
	$data->{description} = '' unless $data->{description};
	
	my $result = try {
		$self->pg->db->insert('order_items', {
									order_head_fkey => $order_head_pkey,
									itemno => $data->{itemno},
									stockitem => $data->{stockitem},
									description => $data->{description},
									quantity => $data->{quantity},
									price => $data->{price},
								},
								{
									on_conflict => \[
										'(order_head_fkey, itemno) Do update set moddatetime = ?', 'now()'],
									returning => 'order_items_pkey'
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
	)->set_setdefault_data($data, 'order_items');

	return $data, $fields;
}

sub get_table_column_names {
	my $self = shift;

	my $fields;
	$fields = Daje::Utils::Postgres::Columns->new(
		pg => $self->pg
	)->get_table_column_names('order_items');

	return $fields;
}
1;
