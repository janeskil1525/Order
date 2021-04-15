package Order::Helper::Shoppingcart::Cart::LoadBasket;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures;

use Try::Tiny;

use Order::Helper::Shoppingcart::Address;
use Order::Helper::Shoppingcart::Item;

has 'pg';

sub loadBasket{
    my($self, $basketid, $settings, $transtation) = @_;

    my $grid_fields_list = $settings->get_settings_list('Basket_grid_fields',0,0 );
    my $details_fields_list = $settings->get_settings_list('Basket_details_fields',0,0 );
    my $address_fields_list = $settings->get_settings_list('Basket_address_fields',0,0 );

    my $selectnames = Order::Helper::Selectnames->new();
    my $gridfields = $selectnames->get_select_names($grid_fields_list);
    my $detailsfields = $selectnames->get_select_names($details_fields_list);
    my $addressfields = $selectnames->get_select_names($address_fields_list);

    my $baskethead = try {
        $self->pg->db->select('basket', $detailsfields, { basketid => $basketid })->hash;
    } catch {
        $self->capture_message('Order','[Order::Helper::Shoppingcart::Cart::LoadBasket] load baskethead', (ref $self), (caller(0))[3], $_);
        say $_;
    };

    my $basket->{details} = try {
        $transtation->details_headers('Basket_details_fields',
            $details_fields_list, $baskethead,'swe');
    }catch{
        $self->capture_message('Order','[Order::Helper::Shoppingcart::Cart::LoadBasket]', (ref $self), (caller(0))[3], $_);
        say $_;
    };

    my $item = Order::Helper::Shoppingcart::Item->new(pg => $self->pg);
    my $address = Order::Helper::Shoppingcart::Address->new(pg => $self->pg);

    $basket->{data} = $item->getItems($basket->{details}->{basket_pkey}->{value},$gridfields);

    $basket->{headers} =  try {
        $transtation->grid_header('Basket_grid_fields',$grid_fields_list,'swe');
    }catch{
        $self->capture_message('Order','Order::Helper::Shoppingcart::Cart::LoadBasket 2', (ref $self), (caller(0))[3], $_);
        say $_;
    };

    $basket->{details}->{invoiceaddress} = try {
        my $address = $address->loadAddress(
            $basket->{details}->{basket_pkey}->{value},'Invoice', $addressfields);
        $transtation->details_headers(
            'Basket_address_fields', $address_fields_list, $address ,'swe');
    }catch{
        $self->capture_message('Order','Order::Helper::Shoppingcart::Cart::LoadBasket 3', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    $basket->{details}->{deliveryaddress} = try {
        $transtation->details_headers(
            'Basket_address_fields', $address_fields_list, $address->loadAddress(
            $basket->{details}->{basket_pkey}->{value},'Delivery', $addressfields),'swe');
    }catch{
        $self->capture_message('Order','Order::Helper::Shoppingcart::Cart::LoadBasket 4', (ref $self), (caller(0))[3], $_);
        say $_;
    };

    return $basket;
}

1;