package Order::Helper::Orion::Processor;
use Mojo::Base 'Order::Helper::Orion::Communicator::Base';

use Mojo::JSON qw{to_json from_json};
use Order::Helper::Orion::CreateOrder;
use Order::Helper::Orion::Data::CreateData;
use Try::Tiny;

has 'pg';
has 'config';

sub process_order {
    my ($self, $salesorderhead_pkey) = @_;

    my ($ordehead, $addresses, $orderitems) = Order::Helper::Orion::Data::CreateData->new(
        pg => $self->pg
    )->create_data(
        $salesorderhead_pkey
    );

    my $orion_order = Order::Helper::Orion::CreateOrder->new(

    )->orion_order(
        $ordehead, $addresses, $orderitems
    );
    $self->username($ordehead->{orion_auth}->{username});
    $self->password($ordehead->{orion_auth}->{password});

    my $result = $self->send_order($orion_order);

    return $result;
}

sub send_order {
    my ($self, $orion_order, $ordehead) = @_;

    my $result;
    my $orion_order_json = to_json $orion_order;
    my $res = try {
        $self->post_data($orion_order_json)->result;
    } catch {
        say $_;
    };

    if($res->is_success)  {
        $result = '1';
    } elsif ($res->is_error){
        say  $res->message . ' ' . $res->code . ' ' . $res->body;
        $result = $res->message . ' ' . $res->code . ' ' . $res->body;
    }

    say $res->body;
    return $result;
}


1;