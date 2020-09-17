package Order::Helper::Orion::Data::Base;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::JSON qw{to_json};
use DateTime;
use Daje::Utils::MicrosoftDateFormat;

sub hash {
    my $self = shift;

    my $result;
    my @keys = keys %{ $self };
    my @values = values %{ $self };
    while (@keys) {
        my $tag = pop(@keys);
        my $value = pop(@values);
        $result->{$tag} = $value;
        if(ref $result->{$tag} eq 'DateTime'){
            my $date = Daje::Utils::MicrosoftDateFormat->new();
            $result->{$tag} = $date->create_date($value);
        }
    }

    return $result;
}

sub json {
    my $self = shift;

    my $hash = $self->hash();

    my @keys = keys %{ $hash };
    my @values = values %{ $hash };
    while (@keys) {
        my $tag = pop(@keys);
        my $value = pop(@values);
        if(ref $hash->{$tag} eq 'DateTime'){
            my $date = Daje::Utils::MicrosoftDateFormat->new();
            $hash->{$tag} = $date->create_date($value);
        }
    }

    my $json = to_json($hash);

    return $json;
}
1;