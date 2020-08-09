package Order::Helper::Shoppingcart::Cart;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Helper::Shoppingcart::Check::CartData;
use Order::Helper::Shoppingcart::Item;
use Order::Helper::Shoppingcart::Address;
use Order::Helper::Selectnames;
use Order::Helper::Translations;
use Order::Model::User;
#use Daje::Utils::Addresses::Company;

use Try::Tiny;

has 'pg';

   
sub getOpenBasketId{
    my ($self, $users_pkey) = @_;

    my $result = try{
        $self->pg->db->select(
        'basket',
        'basketid',
        {
            users_fkey => $users_pkey,
            approved => 'false',
            status => 'NEW'
        })->hash;
    }catch{
        $self->capture_message('','Shoppingcart::Cart', (ref $self), (caller(0))[3], $_);
        say $_;
    };

    return $result;
}

sub openBasket{
    my ($self, $userid, $company) = @_;

    my $result->{openitems} = try{ $self->pg->db->select(
                ['basket',['basket_item', basket_fkey  => 'basket_pkey']],
                ['basket_pkey'],
                {
                    userid          => $userid,
                    company         => $company,
                    approved        => 'false',
                    status           => 'NEW',
                    quantity        => {'>' => 0}
                })->rows();
    }catch{
        $self->capture_message('','Shoppingcart::Cart::openBasket]', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    
    return $result;
}

sub dropBasket{
    my($self, $basketid) = @_;
    
    my $basket_pkey = $self->getBasketPkey($basketid);
    my $result = try {
        my $tx = $self->pg->db->begin();
        
        Shoppingcart::Item->new(pg => $self->pg)->dropItems($basket_pkey);
        Shoppingcart::Address->new(pg => $self->pg)->dropAddresses($basket_pkey);
        
        $self->pg->db->delete('basket', {'basket_pkey' => $basket_pkey});
        $tx->commit();
        
        my $result->{deleted} = $basket_pkey;
        return $result;
    }catch {
        my $result;
        $result->{error} = $_->{message};
        $self->capture_message('','Shoppingcart::Cart::dropBasket]', (ref $self), (caller(0))[3], $_);
        return $result;
    };
    
    return $result;    
}

sub loadBasket{
    my($self, $basketid, $grid_fields_list, $details_fields_list, $address_fields_list) = @_;
    
    my $transtation = Daje::Utils::Translations->new(pg => $self->pg);
    my $selectnames = Daje::Utils::Selectnames->new();
    my $gridfields = $selectnames->get_select_names($grid_fields_list);
    my $detailsfields = $selectnames->get_select_names($details_fields_list);
    my $addressfields = $selectnames->get_select_names($address_fields_list);
    
    my $basket->{details} = try {
        $transtation->details_headers('Basket_details_fields',
            $details_fields_list, $self->getBasketHead($basketid, $detailsfields),'swe');
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasket]', (ref $self), (caller(0))[3], $_);
        say $_;  
    };
    
    my $item = Shoppingcart::Item->new(pg => $self->pg);
    my $address = Shoppingcart::Address->new(pg => $self->pg);
    
    $basket->{data} = $item->getItems($basket->{details}->{basket_pkey}->{value},$gridfields);
    $basket->{headers} =  try {
        $transtation->grid_header('Basket_grid_fields',$grid_fields_list,'swe');
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasket 2', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    $basket->{details}->{invoiceaddress} = try {
        $transtation->details_headers(
        'Basket_address_fields', $address_fields_list, $address->loadAddress(
            $basket->{details}->{basket_pkey}->{value},'Invoice', $addressfields, $basket->{details}->{companies_fkey}->{value}),'swe');
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasket 3', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    $basket->{details}->{deliveryaddress} = try{
        $transtation->details_headers(
        'Basket_address_fields', $address_fields_list, $address->loadAddress(
            $basket->{details}->{basket_pkey}->{value},'Delivery', $addressfields, $basket->{details}->{companies_fkey}->{value}),'swe');
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasket 4', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    
    return $basket;
}

sub loadBasketFull{
    my($self, $basketid) = @_;
        
    my $basket->{details} = try {
        $self->getBasketHead($basketid, undef);
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasketFull', (ref $self), (caller(0))[3], $_);
        say $_;  
    };
    
    my $item = Shoppingcart::Item->new(pg => $self->pg);
    my $address = try {
        Shoppingcart::Address->new(pg => $self->pg);
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasketFull 2', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    
    $basket->{data} = try{
        $item->getItems($basket->{details}->{basket_pkey},undef);
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasketFull 3', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    $basket->{details}->{invoiceaddress} = try {
        $address->loadAddress($basket->{details}->{basket_pkey},'Invoice', undef);
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasketFull 4', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    $basket->{details}->{deliveryaddress} = try{
        $address->loadAddress($basket->{details}->{basket_pkey},'Delivery', undef);
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasketFull 5', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    
    return $basket;
}

sub getBasketHead{
    my ($self, $basketid, $detailsfields) = @_;
    
    my $basket_head = try {
        $self->pg->db->select('basket', $detailsfields, {basketid => $basketid})->hash;
    }catch{
        $self->capture_message('','Shoppingcart::Cart::getBasketHead', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    return $basket_head;
}

sub setStatusOrder{
    my($self, $basketid) = @_;
    
    my $basket_pkey = $self->getBasketPkey($basketid);
    
    my $basket_data->{status} = 'Order created';
            
    $self->pg->db->update(
         'basket', $basket_data
          ,{basket_pkey => $basket_pkey}
    );
}

sub saveBasket{
    my($self, $data, $checkout) = @_;
    
    
    my $check = Shoppingcart::Check::CartData->new();
    $data->{invoiceaddress} = $check->sanitizeAddress(
        $data->{invoiceaddress}
    ) if exists $data->{invoiceaddress};

    $data->{deliveryaddress} = $check->sanitizeAddress(
        $data->{deliveryaddress}
    ) if exists $data->{deliveryaddress};
    
    my $user = $self->pg->db->select(
        ['users_token',
        ['users_companies', 'users_companies.users_fkey' => 'users_token.users_fkey']],
        ['users_companies.users_fkey', 'users_companies.companies_fkey'],
        {token => $data->{token}}
    )->hash;

    my $basket_pkey = $self->getBasketPkey($data->{basketid});
   
    eval{
			my $tx = $self->pg->db->begin();
            say " saveBasket in eval 1";
            my $basket_data;
            if($checkout){
                $basket_data->{status} = 'Checkout in progress';
                $basket_data->{approved} = 'true';
            }
            $data->{payment} = 'Invoice' unless $data->{payment};
            $basket_data->{payment} = $data->{payment};
            $basket_data->{users_fkey} = $user->{users_fkey};
            $basket_data->{companies_fkey} = $user->{companies_fkey};
        say " saveBasket in eval 2";
            $self->pg->db->update('basket',
                                    $basket_data
                                    ,{
                                    basket_pkey => $basket_pkey}
                                );
            
            my $address = Shoppingcart::Address->new(pg => $self->pg);
            if (exists $data->{invoiceaddress}){
                my $basket_addresses_fkey = $address->addressExists($basket_pkey, 'Invoice');
                if($basket_addresses_fkey){
                    $address->updateAddress($basket_addresses_fkey, $data->{invoiceaddress});
                }else{
                    $address->upsertAddress($basket_pkey, $data->{invoiceaddress},'Invoice') ;
                }                
            }
        say " saveBasket in eval 3";
             if (exists $data->{deliveryaddress}){
                my $basket_addresses_fkey = $address->addressExists($basket_pkey, 'Delivery');
                if($basket_addresses_fkey){
                    $address->updateAddress($basket_addresses_fkey, $data->{deliveryaddress});
                }else{
                    $address->upsertAddress($basket_pkey, $data->{deliveryaddress},'Delivery') ;
                }                
            }
        say " saveBasket in eval 4";
            $tx->commit();

	};

    $self->capture_message('','Shoppingcart::Cart::getBasketHead', (ref $self), (caller(0))[3], $@) if $@;
	return  {error => $@} if $@;
	return {basket_pkey => $basket_pkey, basketid => $data->{basketid}};
}

sub upsertItem{
    my($self, $data) = @_;
	
	my $basket_pkey = $self->getBasketPkey($data->{basketid});		
	eval{
			my $tx = $self->pg->db->begin();

			if ($basket_pkey == 0){
                my $user = Daje::Model::User->new(pg => $self->pg);
                my $users_company_pkey = $user->load_token_user_company_pkey(
                    $data->{token})->hash;

				$basket_pkey = $self->pg->db->insert(
                    'basket',
						{
                            basketid => $data->{basketid},
                            users_fkey => $users_company_pkey->{users_pkey},
                            companies_fkey => $users_company_pkey->{companies_pkey}
                        },
						{
                            returning => 'basket_pkey'
                        }
                )->hash->{basket_pkey};
                my $defaultaddress = Daje::Utils::Addresses::Company->new(
                    pg => $self->pg )->load_address($users_company_pkey->{companies_pkey});

                my $address = Shoppingcart::Address->new(pg => $self->pg);
                $address->upsertAddress($basket_pkey, $defaultaddress,'Invoice');
                $address->upsertAddress($basket_pkey, $defaultaddress,'Delivery');
			}
			my $item = Shoppingcart::Item->new(pg => $self->pg);
			$data->{basket_pkey} = $basket_pkey;
			$item->upsertItem($data);
			
		 $tx->commit();
	};
    my $local = $@;
    $self->capture_message('','Shoppingcart::Cart::upsertItem', (ref $self), (caller(0))[3], $local) if $local;
    my $result;
	if($local){
        $result->{result} = $local;
    }else{
        $result->{result} = "Success";
    }

	return $result;
}

sub getBasketPkey{
    my ($self, $basketid) =@_;
    
    my $basket = $self->pg->db->select('basket', ['basket_pkey'], {basketid => $basketid});
    
    my $basket_pkey;
    if($basket->rows > 0){
        $basket_pkey = $basket->hash->{basket_pkey};
        $basket->finish;
    }
    
    $basket_pkey = 0 unless $basket_pkey;
    
    return $basket_pkey;
}


1;
