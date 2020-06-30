package Matorit::Controller::Users;
use Mojo::Base 'Mojolicious::Controller';


sub list{
	my $self = shift;

	$self->render_later;
	$self->users->list_p()->then(sub{
		my $result = shift;		
		
		my $collection = $result->hashes;
		$self->render(
			template => 'users/users_list',
			users => $collection,
			number_of_hits => $collection->size(),
		);		
	})->catch(sub{
		my $err = shift;

		say $err;
	})->wait();
	
}

1;