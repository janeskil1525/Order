package Order::Helper::Messenger::Message;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::UserAgent;
use Daje::Utils::Sentinelsender;

has 'message' => '';
has 'title' => '';
has 'subtitle' => '';
has 'highSubtitle' => '';
has 'subContent' => '';
has 'error' => 'false';
has 'company' => '';
has 'userid' => '';
has 'type' => 'notice';
has 'supplier' => '';

has 'config';

sub init {
    my ($self, $minion) = @_;

    $minion->minion->add_task(send_message => \&_send_message);
}

sub _send_message{
    my($job, $data) = @_;

    my $result = send_message($job->app->pg, $job->pp->config, $data);

    $job->finish({ status => $result});
}


sub send_message_test {
    my ($self, $pg, $config, $data) = @_;

    my $result = send_message($pg, $config, $data);

    return $result;
}

sub send_message {
    my ($pg, $config, $payload) = @_;

    my $ua = Mojo::UserAgent->new();
    my $key = $config->{webshop}->{key};

    my $address = $config->{webshop}->{address} . $config->{webshop}->{messenger_endpoint};
    my $tx = $ua->post(
        $address => {
            Accept => '*/*', 'X-Token-Check' => $key
        } => json => $payload
    );

    if(not $tx->result->is_success){
        say $tx->result->message;
        Daje::Utils::Sentinelsender->new()->capture_message(
            '','Order::Helper::Rfqs::Message::send_message', 'send_message', (caller(0))[3], $tx->result->message
        );
    }

}
1;