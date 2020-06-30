package Daje::Order::Summary;
use Mojo::Base 'Daje::Utils::Sentry::Raven';

use Daje::Model::OrderHead;;
use Mojo::JSON qw {decode_json };

has 'pg';

sub get_summary{
    my ($self, $order_head_pkey) = @_;

    my $orderhead = Daje::Model::OrderHead->new(
        pg => $self->pg
    )->load_order_head(
        $order_head_pkey
    )->hash;

    return "Order nr. " . $orderhead->{order_no} . "\n Order datum " . substr($orderhead->{orderdate},0,10);
}
1;