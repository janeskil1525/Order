package Order::Controller::Login;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;


sub showlogin {
	my $self = shift;

	my $is_logged_in = $self->app->yancy->auth->require_user;
	say "Is logged in " . Dumper($is_logged_in);
	say "in showlogin";
	say "Current user " . $self->yancy->auth->current_user;
	#say Dumper($self->yancy->auth->current_user);
	return $self->redirect_to('/yancy')
		if ($self->yancy->auth->current_user);
	$self->render(template => 'logon/logon');
}

sub login{
	my $self = shift;

	say "In Login";
	say "Current user " . $self->yancy->auth->current_user;
	if($self->yancy->auth->current_user) {
		$self->session->{auth} = 1;
		return $self->redirect_to('/yancy');
	}

	$self->redirect_to($self->config->{webserver});
	$self->flash('error' => 'Wrong login/password');
}

1;
