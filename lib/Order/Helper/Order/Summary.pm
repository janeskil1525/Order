package Order::Helper::Order::Summary;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Model::SalesOrderHead;
use Order::Model::PurchaseOrderHead;

use Mojo::JSON qw {decode_json };

has 'pg';

sub get_salesorder_summary{
    my ($self, $order_head_pkey) = @_;

    my $orderhead = Order::Model::SalesOrderHead->new(
        pg => $self->pg
    )->load_order_head(
        $order_head_pkey
    )->hash;

    return "Order nr. " . $orderhead->{order_no} . "\n Order datum " . substr($orderhead->{orderdate},0,10);
}

sub get_purchaseorder_summary{
    my ($self, $order_head_pkey) = @_;

    my $orderhead = Order::Model::PurchaseOrderHead->new(
        pg => $self->pg
    )->load_order_head(
        $order_head_pkey
    )->hash;

    return "Order nr. " . $orderhead->{order_no} . "\n Order datum " . substr($orderhead->{orderdate},0,10);
}

1;