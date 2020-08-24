package Order::Helper::Shoppingcart::Converter;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Data::Dumper;
use Order::Helper::Order::Notice;
use Order::Helper::Order::Import;
use Order::Helper::Shoppingcart::Cart;
use Order::Helper::Order;

sub init {
    my ($self, $minion) = @_;

    $minion->add_task(create_orders => \&_create_orders);
}

sub _create_orders {
    my($job, $data) = @_;


    my $pg = $job->app->pg;
    my $config = $job->pp->config;
    my $result = create_orders($pg, $data, $config);

    if($result){
        $job->finish({ status => 'success'});
    }else{
        $job->finish({ status => 'failed'});
    }

}

sub create_orders {
    my($pg, $data, $config) = @_;

    my $salesorder_notice = Order::Helper::Order::Notice->new(
        pg => $pg,
        config => $config
    );
    my $purchaseorder_notice = Order::Helper::Order::Notice->new(
        pg => $pg,
        config => $config
    );

    my $basket = Order::Helper::Shoppingcart::Cart->new(
        pg => $pg
    )->loadBasketFull(
        $data->{basketid}
    );
    my $order = Order::Helper::Order::Import->new(pg => $pg)->importBasket($basket);
    my $summary = Order::Helper::Order->new(pg => $pg);
    my $result;
    if($order->{success}){
        $basket->setStatusOrder($data->{basketid});

        $salesorder_notice->title('Kundorder');
        my $length = scalar @{$order->{salesorder_head_pkey}};
        try{
            for(my $i = 0; $i < $length; $i++){
                $salesorder_notice->subtitle('Kundorder');
                $salesorder_notice->company(
                    $summary->get_order_company(
                        @{$order->{salesorder_head_pkey}}[$i]
                   )
                );
                $salesorder_notice->message(
                    $summary->get_order_summary(
                        @{$order->{salesorder_head_pkey}}[$i]
                    )
                );

                my $message_hash = $salesorder_notice->get_payload();
                $salesorder_notice->send_notice($message_hash);

            }
        }catch{

            say "[DMojolicious::Plugin::Order::_create_orders] salesorder_head_pkey " . $_;
        };

        $purchaseorder_notice->title('Inköpsorder');
        $length = scalar @{$order->{purchaseorder_head_pkey}};
        try{
            for(my $i = 0; $i < $length; $i++){

                $purchaseorder_notice->subtitle('Inköpsorder');

                $purchaseorder_notice->company($summary->get_order_company(
                    @{$order->{purchaseorder_head_pkey}}[$i]
                ));
                $purchaseorder_notice->message(
                    $summary->get_order_summary(
                        @{$order->{purchaseorder_head_pkey}}[$i]
                    )
                );

                my $message_hash = $purchaseorder_notice->get_payload();
                $purchaseorder_notice->send_notice($message_hash);
            }
        }catch{

            say "[DMojolicious::Plugin::Order::_create_orders] purchaseorder_head_pkey " . $_;
        };

        $result = 1;
    }else{
        $result = 0;
    }
    return $result
}

sub create_orders_test {
    my ($self, $pg, $data, $config) = @_;

    my $result = create_orders($pg, $data, $config);

    return $result;
}
1;