package Order::Controller::Basket;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw{decode_json};
use Data::Dumper;
use Daje::Utils::Sentinelsender;
use Data::UUID;

sub basketid {


    my $ug = Data::UUID->new;
    my $token = $ug->create();
    $token = $ug->to_string($token);
}

sub open_basket{
    my $self = shift;

    my $body = $self->req->body;
    my $data = decode_json($body);

    my $result = $self->shoppingcart->openBasket($data->{userid}, $data->{company});
    
    $self->render(json => $result);
}

sub delete_api{
    my $self = shift;
    
    $self->basket_delete_item();
}

sub upsertitem{
    my $self = shift;

    my $id = 0;
    my $data = $self->req->body;
    say Dumper($data);
    if($data->{supplier}->{settings}->{Has_Active_Orion}->{setting_properties}->{has_orion})
    {
        $id = $self->orionreservation->check_reservation($data->{stockitem});
    }
    if($id == 0){
        my $reservation = 0;
        if($data->{supplier}->{settings}->{Has_Active_Orion}->{setting_properties}->{has_orion})
        {
            $self->orionreservation->endpoint_path(
                $self->app->config->{orion}->{reservation_endpoint_path}
            );
            $self->orionreservation->endpoint_address(
                $self->app->config->{orion}->{address}
            );
            $reservation = $self->orionreservation->add_reservation(
                $data->{stockitem},
                $data->{supplier}->{company}->{company},
                2,
                $data->{supplier}->{settings}->{Orion_Login_Data}->{setting_properties}
            );
        }
        $data->{external_reservation} = $reservation;
        my $result = $self->shoppingcart->upsertItem($data);

        if($result){
            $self->render(
                json => {
                    result => $result,
                    reservation => $reservation
                }
            );
        }else{
            Daje::Utils::Sentinelsender->new()->capture_message(
                '','WebsShop', (ref $self), (caller(0))[3], "Upsert item failed"
            );
            $self->render(
                json => {
                    result => "ERROR",
                    message => "Kunde inte spara denna del, var vänlig och testa igen !"
                }
            );
        }
    } else {
        $self->render(
            json => {
                result => "RESERVED",
                message => "Tyvärr har någon annan användare redan köpt denna artikel, vänligen välj en annan del !"
            }
        );
    }
}

sub savebasket{
    my $self = shift;
    
    my $data = $self->req->body->json;
    my $result = $self->shoppingcart->saveBasket($data);
    $self->render(json => {result => $result});    
}

sub checkout{
    my $self = shift;
    
    my $data = $self->req->body;
    my $hash = decode_json($data);
    my $result = $self->shoppingcart->checkOut($hash, $self->app->minion);

    $self->render(json => {result => $result});    
}

sub getForRegPlate{
    my $self = shift;
    
     $self->render_later;
     $self->render(json => {forregplate => "0"});
    
}

sub load_basket{
    my $self = shift;
    
    my $basketid = $self->param('basketid');

    my $response = $self->shoppingcart->loadBasket($basketid);

    $self->render(json => {basket => $response});
    
}

sub search_api{
    my $self = shift;
    
    my $basket = $self->param('basket');
    $self->render_later;

    $self->search_basket_p($basket);
    
}

sub list_basket_items_itemtype_api{
    my $self = shift;

    $self->render_later;
    my $validator = $self->validation;
    my $token = $self->req->headers->header('X-Token-Check');
    my $fields_list = $self->settings->get_settings_list('RFQs_search_grid_fields', $token);
    my $response->{headers} = $self->translations->grid_header('RFQs_search_grid_fields',$fields_list,'swe');

    if($validator->required('itemtype')){
        my $itemtype = $self->param('itemtype');

        $self->shoppingcart->list_basket_items_itemtype_p($itemtype, $token)->then(sub{
            my $items = shift;
            $response->{data} = $items->hashes->to_array;;
            $response->{responses} = $items->rows;

            $self->render(json => $response);
        })->catch(sub {
            my $err = shift;

            $self->render(json => {error => $err});
        })->wait;
    }
}

sub basket_items_load_api{
    my $self = shift;

    $self->render_later;
    my $validator = $self->validation;
    if($validator->required('basket_item_pkey')){
        my $basket_item_pkey = $self->param('basket_item_pkey');
        $self->shoppingcart->basket_items_load_p($basket_item_pkey)->then(sub{
            my $result = shift;

            my $field_list;
            my $basket_item = $result->hash;
            $result->finish;
            ($basket_item, $field_list) = $self->shoppingcart->set_setdefault_item_data($basket_item);

            my $detail = Daje::Utils::Translations->new(
                pg => $self->pg
            )->details_headers(
                'basket_item', $field_list, $basket_item, 'swe');

            $basket_item->{header_data} = $detail;

            $self->render(json => $basket_item);
        })->catch(sub {
            my $err = shift;

            my $basket_item->{header_data} ='';
            $basket_item->{error} = "Could not load Basket item";
            say $err;
            $self->render(json => $basket_item);
        })->wait;
    }
}

1;
