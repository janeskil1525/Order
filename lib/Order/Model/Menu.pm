package Order::Model::Menu;
use Mojo::Base 'Daje::Utils::Sentinelsender';

has 'pg';

sub list {
	my($self, $conditions) = @_;

	return $self->pg->db->select_p('menu',
		[
			'menu',
			'menu_path',
		],
		undef,
		{
			'order_by' => 'menu_order'
		}
	);
}
1;