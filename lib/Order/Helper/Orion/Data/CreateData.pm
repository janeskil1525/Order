package Order::Helper::Orion::Data::CreateData;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::JSON qw {from_json decode_json};
use Order::Model::SalesOrderHead;
use Order::Model::SalesOrderItem;
use Order::Model::BasketAdresses;
use Try::Tiny;

has 'pg';

sub create_data{
    my ($self, $salesorderhead_pkey) = @_;

    my $ordehead = $self->load_orderhead($salesorderhead_pkey);
    my $addresses = $self->load_addresses($ordehead->{externalref});
    my $orderitems = $self->load_orderitems($salesorderhead_pkey);

    return ($ordehead, $addresses, $orderitems);
}

sub load_orderhead {
    my ($self, $salesorderhead_pkey) = @_;

    my $ordehead = Order::Model::SalesOrderHead->new(
        pg => $self->pg
    )->load_order_head(
        $salesorderhead_pkey
    )->hash;

    my $settings = from_json $ordehead->{settings};
    my $orion_auth->{username} = $settings->{Orion_Login_Data}->{setting_properties}->{username};
    $orion_auth->{password} = $settings->{Orion_Login_Data}->{setting_properties}->{password};
    $ordehead->{orion_auth} = $orion_auth;

    return $ordehead;
}

sub load_addresses{
    my ($self, $basketid) = @_;

    my $adresses;
    my $adressesarr = Order::Model::BasketAdresses->new(
        pg => $self->pg
    )->load_adresses_for_order(
        $basketid
    );

    foreach my $address (@{$adressesarr}) {
        $adresses->{$address->{address_type}} = $address;
    }

    return $adresses;
}

sub load_orderitems {
    my ($self, $salesorderhead_pkey) = @_;

    my $orderitems;
    my $orderitemsarr = Order::Model::SalesOrderItem->new(
        pg => $self->pg
    )->load_order_items(
        $salesorderhead_pkey
    );

    my $length = scalar @{$orderitemsarr};
    for(my $i = 0; $i < $length; $i++){
        my $item = @{$orderitemsarr}[$i];
        my $extradata_hash = try {
            from_json($item->{extradata});
        } catch {
            say $_;
        };
        $item->{extradata_hash} = $extradata_hash;
        push @{$orderitems}, $item;
    }

    return $orderitems;
}
1;