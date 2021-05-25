package Order::Helper::Shoppingcart::Converter;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Mojo::JSON qw {to_json};

use Data::Dumper;
use Order::Helper::Messenger::Notice;
use Order::Helper::Order::Import;
use Order::Helper::Order;
use Order::Model::SalesOrderHead;
use Order::Model::PurchaseOrderHead;
use Order::Helper::Messenger::Message;
use Messenger::Helper::Client;
use Try::Tiny;

sub init ($self, $minion) {

    $minion->add_task(create_orders => \&_create_orders);
}

sub _create_orders ($job, $data) {

    my $pg = $job->app->pg;
    my $config = $job->app->config;
    my $messenger = $job->app->messenger;
    create_orders($pg, $data, $config, $messenger)->then(sub ($result) {

        $job->finish({ status => 'success'});
    })->catch(sub ($err) {

        $job->finish({ status => $err});
    })->wait;
}

async sub create_orders ($pg, $basket, $config, $messenger) {

    my $order = Order::Helper::Order::Import->new(pg => $pg)->importBasket($basket);
    my $result;
    if($order->{success}) {
        #$basket->setStatusOrder($data->{basketid});
        my $message = Order::Helper::Messenger::Message->new(config => $config);
        my $length = scalar @{$order->{salesorder_head_pkey}};

            for(my $i = 0; $i < $length; $i++) {
                my $salesorder_notice = Order::Helper::Messenger::Notice->new();
                $salesorder_notice->title('Kundorder');
                my $summary = Order::Model::SalesOrderHead->new(pg => $pg);
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

            # Daje::Utils::Sentinelsender->new()->capture_message(
            #     '', 'Order::Helper::Shoppingcart::Converter::create_orders', 'create_orders', (caller(0))[3], $_
            # );
            # say "[Order::Helper::Shoppingcart::Converter::create_orders]  " . $_;



        $length = scalar @{$order->{purchaseorder_head_pkey}};

            for(my $i = 0; $i < $length; $i++) {
                my $purchaseorder_notice = Order::Helper::Messenger::Notice->new(
                    pg => $pg,
                    config => $config
                );
                $purchaseorder_notice->title('Inköpsorder');
                my $summary = Order::Model::PurchaseOrderHead->new(pg => $pg);
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


            # Daje::Utils::Sentinelsender->new()->capture_message(
            #     '', 'Order::Helper::Shoppingcart::Converter::create_orders', 'create_orders', (caller(0))[3], $_
            # );
            # say "[Order::Helper::Shoppingcart::Converter::create_orders]  " . $_;


        $result = 1;
    } else {
        $result = 0;
    }

    return $result
}

sub create_orders_test ($self, $pg, $data, $config, $messenger) {

    create_orders($pg, $data, $config, $messenger)->then(sub ($result){
        return 1;
    })->catch(sub ($err) {
       return $err;
    })->wait;

}
1;