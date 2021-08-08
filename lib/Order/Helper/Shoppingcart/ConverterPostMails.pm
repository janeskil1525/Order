package Order::Helper::Shoppingcart::ConverterPostMails;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;

use Mojo::JSON qw {to_json};

has 'pg';

async sub post_conversion_mails($self, $basket, $order, $translations, $mailer) {

    $basket->{lan} = 'swe' unless exists $basket->{lan} and $basket->{lan};

    my ($purchaseorder_template, $salesorder_template) = await $self->load_templates($basket->{lan});

}

async sub process_purchase_template ($self, $purchaseorder_template, $basket, $order, $translations) {

}

async sub load_templates ($self, $lan) {
    my $purchaseorder_template = $translations->load_template('purchaseorder_confirmation', $lan);
    my $salesorder_template = $translations->load_template('salesorder_confirmation', $lan);

    return ($purchaseorder_template, $salesorder_template);
}
1;