package Order::Helper::Shoppingcart::Converter;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Mojo::JSON qw {to_json};

use Data::Dumper;
use Order::Helper::Shoppingcart::ConverterPostMessages;
use Order::Helper::Shoppingcart::ConverterPostMails;
use Order::Helper::Order::Import;
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
    my $translations = $job->app->translations;
    my $mailer = $job->app->mailer;

    create_orders($pg, $data, $config, $messenger, $translations, $mailer)->then(sub ($result) {

        $job->finish({ status => 'success'});
    })->catch(sub ($err) {

        $job->finish({ status => $err});
    })->wait;
}

async sub create_orders ($pg, $basket, $config, $messenger, $translations, $mailer) {

    my $order = Order::Helper::Order::Import->new(
        pg => $pg
    )->importBasket(
        $basket
    );

    my $result;
    if($order->{success}) {
        await Order::Helper::Shoppingcart::ConverterPostMessages->new(
            pg => $pg
        )->post_conversion_messages(
            $basket, $order, $messenger, $config
        );

        await Order::Helper::Shoppingcart::ConverterPostMails->new(
            pg => $pg
        )->post_conversion_mails(
            $basket, $order, $translations, $mailer
        );

        $result = 1;
    } else {
        $result = 0;
    }

    return $result
}

sub create_orders_test ($self, $pg, $data, $config, $messenger, $mailer) {

    create_orders($pg, $data, $config, $messenger, $mailer)->then(sub ($result){
        return 1;
    })->catch(sub ($err) {
       return $err;
    })->wait;

}
1;