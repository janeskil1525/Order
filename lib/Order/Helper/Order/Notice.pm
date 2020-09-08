package Order::Helper::Order::Notice;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::UserAgent;

has 'message' => '';
has 'title' => '';
has 'subtitle' => '';
has 'highSubtitle' => '';
has 'subContent' => '';
has 'error' => 'false';
has 'company' => '';
has 'userid' => '';
has 'type' => 'notice';

has 'config';
has 'pg';

sub get_payload{
    my $self= shift;

    my $payload->{title} = $self->title();
    $payload->{subtitle} = $self->subtitle();
    $payload->{highSubtitle} = $self->highSubtitle();
    $payload->{subContent} = $self->subContent();
    $payload->{company} = $self->company();
    $payload->{userid} = $self->userid();
    $payload->{type} = $self->type();
    $payload->{message} = $self->message();
    $payload->{error} = $self->error();

    return $payload;
}

sub send_notice {
    my ($self, $payload) = @_;

    my $ua = Mojo::UserAgent->new();
    my $key = $self->config->{webshop}->{key};

    my $address = $self->config->{webshop}->{address} . $self->config->{webshop}->{messenger_endpoint};
    my $tx = $ua->post(
        $address => {
            Accept => '*/*', 'X-Token-Check' => $key
        } => json => $payload
    );

   if(not $tx->result->is_success){
        say $tx->result->message;
        $self->capture_message(
            '','Order::Helper::Order::Notice::send_notice', (ref $self), (caller(0))[3], $tx->result->message
        );
    }

}
1;