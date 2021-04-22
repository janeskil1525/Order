package Order::Controller::Basket;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::JSON qw{decode_json};
use Data::Dumper;
use Daje::Utils::Sentinelsender;
use Data::UUID;
use Try::Tiny;

sub checkout ($self) {
    
    my $data = $self->req->body;
    my $hash = decode_json($data);
    my $result = try {
        $self->app->minion->enqueue('create_orders' => [$hash] => {priority => 0});
        return 'Success'
    } catch {
        return $_;
    };

    $self->render(
        json => {
            result => $result
        }
    );
}
1;
