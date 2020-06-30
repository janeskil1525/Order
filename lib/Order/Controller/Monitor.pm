package Matorit::Controller::Monitor;
use Mojo::Base 'Mojolicious::Controller';

use Daje::Model::Pulser;

sub list{
	my $self = shift;
	
	$self->render_later;
	Daje::Model::Pulser->new(
			pg => $self->app->pg
	)->list_p()->then(sub{
		my $result = shift;		
		
		my $collection = $result->hashes;
		$self->render(
			template => 'monitor/monitor_list',
			monitors => $collection,
			number_of_hits => $collection->size(),
		);		
				
	})->catch(sub{
		
	})->wait;
	
	
}

1;