package Matorit::Controller::Companies;
use Mojo::Base 'Mojolicious::Controller';


sub list{
	my $self = shift;

	$self->render_later;
	$self->companies->list_matorit_p()->then(sub{
		my $result = shift;

		my $collection = $result->hashes;
		$self->render(
			template => 'companies/companies_list',
			companies => $collection,
			number_of_hits => $collection->size(),
		);
	})->catch(sub{
		my $err = shift;

		say $err;
	})->wait();

}

1;