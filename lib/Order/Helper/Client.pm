package Order::Helper::Client;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Mojo::UserAgent;
use Mojo::JSON qw {decode_json};

has 'endpoint_address';
has 'key';

async sub checkout ($self,  $userid, $company, $system, $basket_data) {

    my $ua = Mojo::UserAgent->new();
    my $post_data;
    $post_data->{userid} = $userid;
    $post_data->{company} = $company;
    $post_data->{system} = $system;
    $post_data->{basket} = $basket_data;

    my $res = $ua->post(
        $self->endpoint_address() . '/api/v1/basket/checkout/' =>
            {'X-Token-Check' => $self->key()} =>
            json => $post_data
    )->result;

    my $body;
    if($res->is_error){
        $self->capture_message(
            'Order', 'Order::Helper::Client::checkout', 'Order::Helper::Client',
            (caller(0))[3], $res->message
        );
        say $res->message;
    } else {
        $body = $res->body;
    }

    my $result;
    if($body){
        $result = decode_json($body);
    } else {
        $result->{result} = '';
    }

    return $result->{result};
}

async sub export ($self, $system) {

    my $ua = Mojo::UserAgent->new();
    my $post_data->{system} = $system;

    my $res = $ua->post(
        $self->endpoint_address() . '/api/v1/order/export/' =>
            {'X-Token-Check' => $self->key()} =>
            json => $post_data
    )->result;

    my $body;
    if($res->is_error){
        $self->capture_message(
            'Order', 'Order::Helper::Client::export', 'Order::Helper::Client',
            (caller(0))[3], $res->message
        );
        say $res->message;
    } else {
        $body = $res->body;
    }

    my $result;
    if($body){
        $result = decode_json($body);
    } else {
        $result->{result} = '';
    }

    return $result->{result};

}
1;