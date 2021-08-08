package Order::Helper::Shoppingcart::ConverterPostMessages;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Order::Helper::Messenger::Notice;
use Order::Model::SalesOrderHead;
use Order::Model::PurchaseOrderHead;
use Mojo::JSON qw {to_json};

has 'pg';

async sub post_conversion_messages($self, $basket, $order, $messenger, $config) {

    my $length = scalar @{$order->{salesorder_head_pkey}};

    for(my $i = 0; $i < $length; $i++) {
        my $salesorder_notice = Order::Helper::Messenger::Notice->new();
        $salesorder_notice->title('Kundorder');
        my $summary = Order::Model::SalesOrderHead->new(pg => $self->pg);
        $salesorder_notice->subtitle('Kundorder');
        $salesorder_notice->company(
            $summary->get_company(
                @{$order->{salesorder_head_pkey}}[$i]
            )
        );

        $salesorder_notice->message(
            $summary->get_summary(
                @{$order->{salesorder_head_pkey}}[$i]
            )
        );

        my $message_hash = $salesorder_notice->get_payload();

        my $response = await $messenger->add_message(
            $salesorder_notice->company(),
            $basket->{system},
            $message_hash
        );

        my $salesorderhead = $summary->load_order_head(@{$order->{salesorder_head_pkey}}[$i]);

        $salesorderhead->{type} = 'salesorder_created';
        $response = await $messenger->add_message(
            $salesorder_notice->company(),
            $basket->{system},
            $salesorderhead
        );
    }

    $length = scalar @{$order->{purchaseorder_head_pkey}};

    for(my $i = 0; $i < $length; $i++) {
        my $purchaseorder_notice = Order::Helper::Messenger::Notice->new(
            pg => $self->pg,
            config => $config
        );
        $purchaseorder_notice->title('Inköpsorder');
        my $summary = Order::Model::PurchaseOrderHead->new(pg => $self->pg);
        $purchaseorder_notice->subtitle('Inköpsorder');

        $purchaseorder_notice->company(
            $summary->get_company(
                @{$order->{purchaseorder_head_pkey}}[$i]
            )
        );

        $purchaseorder_notice->message(
            $summary->get_summary(
                @{$order->{purchaseorder_head_pkey}}[$i]
            )
        );

        my $message_hash = $purchaseorder_notice->get_payload();
        my $response = await $messenger->add_message(
            $purchaseorder_notice->company(),
            $basket->{system},
            $message_hash
        );

        my $purchasorderhead = $summary->load_order_head(@{$order->{purchaseorder_head_pkey}}[$i]);
        $purchasorderhead->{type} = 'purchaseorder_created';

        $response = await $messenger->add_message(
            $purchaseorder_notice->company(),
            $basket->{system},
            $purchasorderhead
        ) ;
    }
}
1;