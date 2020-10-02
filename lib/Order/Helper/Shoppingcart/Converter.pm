package Order::Helper::Shoppingcart::Converter;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Data::Dumper;
use Order::Helper::Messenger::Notice;
use Order::Helper::Order::Import;
use Order::Helper::Shoppingcart::Cart;
use Order::Helper::Order;
use Order::Model::SalesOrderHead;
use Order::Model::PurchaseOrderHead;
use Order::Helper::Messenger::Message;
use Try::Tiny;

sub init {
    my ($self, $minion) = @_;

    $minion->add_task(create_orders => \&_create_orders);
}

sub _create_orders {
    my($job, $data) = @_;


    my $pg = $job->app->pg;
    my $config = $job->app->config;
    my $minion = $job->app->minion;
    my $result = create_orders($pg, $data, $config, $minion);

    if($result){
        $job->finish({ status => 'success'});
    }else{
        $job->finish({ status => 'failed'});
    }

}

sub create_orders {
    my($pg, $data, $config, $minion) = @_;

    my $basket = Order::Helper::Shoppingcart::Cart->new(pg => $pg);

    my $full_basket = $basket->loadBasketFull(
        $data->{basketid}
    );
    my $order = Order::Helper::Order::Import->new(pg => $pg)->importBasket($full_basket);
    #my $summary = Order::Helper::Order->new(pg => $pg);
    my $result;
    if($order->{success}){
        #$basket->setStatusOrder($data->{basketid});
        my $message = Order::Helper::Messenger::Message->new(config => $config);
        my $length = scalar @{$order->{salesorder_head_pkey}};
        try {
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
                $salesorder_notice->companies_fkey(
                    $summary->companies_fkey(
                        @{$order->{salesorder_head_pkey}}[$i]
                    )
                );
                $salesorder_notice->message(
                    $summary->get_summary(
                        @{$order->{salesorder_head_pkey}}[$i]
                    )
                );

                my $message_hash = $salesorder_notice->get_payload();

                send_message (
                    $minion,
                    $message_hash,
                    $salesorder_notice->company(),
                    $salesorder_notice->companies_fkey()
                ) ;
                my $salesorderhead = $summary->load_order_head(@{$order->{salesorder_head_pkey}}[$i]);

                $salesorderhead->{type} = 'salesorder_created';
                send_message (
                    $minion,
                    $salesorderhead,
                    $salesorder_notice->company(),
                    $salesorder_notice->companies_fkey()
                ) ;
            }
        } catch {
            Daje::Utils::Sentinelsender->new()->capture_message(
                '', 'Order::Helper::Shoppingcart::Converter::create_orders', 'create_orders', (caller(0))[3], $_
            );
            say "[Order::Helper::Shoppingcart::Converter::create_orders]  " . $_;
        };


        $length = scalar @{$order->{purchaseorder_head_pkey}};
        try {
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
                $purchaseorder_notice->companies_fkey(
                    $summary->companies_fkey(
                        @{$order->{purchaseorder_head_pkey}}[$i]
                    )
                );

                $purchaseorder_notice->message(
                    $summary->get_summary(
                        @{$order->{purchaseorder_head_pkey}}[$i]
                    )
                );

                my $message_hash = $purchaseorder_notice->get_payload();
                send_message (
                    $minion,
                    $message_hash,
                    $purchaseorder_notice->company(),
                    $purchaseorder_notice->companies_fkey()
                );

                my $purchasorderhead = $summary->load_order_head(@{$order->{purchaseorder_head_pkey}}[$i]);
                $purchasorderhead->{type} = 'purchaseorder_created';

                send_message (
                    $minion,
                    $purchasorderhead,
                    $purchaseorder_notice->company(),
                    $purchaseorder_notice->companies_fkey()
                ) ;
            }
        } catch {

            Daje::Utils::Sentinelsender->new()->capture_message(
                '', 'Order::Helper::Shoppingcart::Converter::create_orders', 'create_orders', (caller(0))[3], $_
            );
            say "[Order::Helper::Shoppingcart::Converter::create_orders]  " . $_;
        };

        $result = 1;
    } else {
        $result = 0;
    }

    return $result
}

sub send_message {
    my ($minion, $data, $company, $companies_fkey, $system) = @_;

    $system = 'LagaPro' unless $system;
    my $message->{payload} = $data;
    $message->{system} = $system;
    $message->{company} = $company;
    $message->{companies_fkey} = $companies_fkey;


    $minion->enqueue('send_message' => [ $message ] => { priority => 0 });
}
sub create_orders_test {
    my ($self, $pg, $data, $config, $minion) = @_;

    my $result = create_orders($pg, $data, $config, $minion);

    return $result;
}
1;