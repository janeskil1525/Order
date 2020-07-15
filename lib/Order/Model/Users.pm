package Order::Model::Users;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Daje::Model::User;

has 'pg';

sub login {
	my ($self, $user, $password) = @_;

	return Daje::Model::User->new(pg => $self->pg)->login_light($user, $password);
}

sub save {
	my ($self, $user) = @_;

	return $self->pg->db->query(qq{
		INSERT INTO users(
			userid, username, passwd)
			VALUES (?, ?, ?)
				ON CONFLICT (userid)
			DO UPDATE
				SET moddatetime = now(),
				editnum = users.editnum + 1,
				username = ?,
				passwd = ?;
	},(
		$user->{userid}, $user->{username}, $user->{passwd}, $user->{username}, $user->{passwd}
	)
	);
}

sub list_p {
	my $self = shift;
	
	return $self->pg->db->select_p('users');
}
1;