package Order::Helper::Settings::GridSettings;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Try::Tiny;
use Mojo::JSON qw{to_json from_json} ;


sub set_grid_settings{
	my ($self, $gridstate, $settings) = @_;
	my $i;
	try {
		my $length = scalar @{$settings};
		for  (my $i = 0; $i < $length; $i++){
			for my $state (@{$gridstate}){
				if($state and exists @{$settings}[$i]->{setting_value} and @{$settings}[$i]->{setting_value} ){
					if(@{$settings}[$i]->{setting_value} eq $state->{colId}){
						my $property = from_json(@{$settings}[$i]->{setting_properties});
						$property->{width} = $state->{width};
						@{$settings}[$i]->{setting_properties} = to_json($property);
					}
				}
			}
		}
	} catch {
		$self->capture_message('','Daje-Utils-GridSettings', (ref $self), (caller(0))[3],  $_ );
		say "NR $i " . $_;
	};
	return $settings;
}
1;
