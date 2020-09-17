package Order::Helper::Shoppingcart::Cart;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Helper::Shoppingcart::Check::CartData;
use Order::Helper::Shoppingcart::LastUsedAddress;
use Order::Helper::Shoppingcart::Item;
use Order::Helper::Shoppingcart::Address;
use Order::Helper::Selectnames;
use Order::Helper::Translations;
use Order::Model::User;
use Data::Dumper;
use Try::Tiny;

has 'pg';
has 'config';

   
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


    my $transtation = Order::Helper::Translations->new(pg => $self->pg);
    my $selectnames = Order::Helper::Selectnames->new();
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

    my $item = Order::Helper::Shoppingcart::Item->new(pg => $self->pg);
    my $address = Order::Helper::Shoppingcart::Address->new(pg => $self->pg);
    
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
    $basket->{details}->{deliveryaddress} = try {
        $transtation->details_headers(
        'Basket_address_fields', $address_fields_list, $address->loadAddress(
            $basket->{details}->{basket_pkey}->{value},'Delivery', $addressfields, $basket->{details}->{companies_fkey}->{value}),'swe');
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasket 4', (ref $self), (caller(0))[3], $_);
        say $_;
    };

    return $basket;
}

sub loadBasketFull {
    my($self, $basketid) = @_;
        
    my $basket->{details} = try {
        $self->getBasketHeadFull($basketid, undef);
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasketFull', (ref $self), (caller(0))[3], $_);
        say $_;  
    };
    
    my $item = Order::Helper::Shoppingcart::Item->new(pg => $self->pg);
    my $address = try {
        Order::Helper::Shoppingcart::Address->new(pg => $self->pg);
    }catch{
        $self->capture_message('','Shoppingcart::Cart::loadBasketFull 2', (ref $self), (caller(0))[3], $_);
        say $_;
    };
    
    $basket->{data} = try{
        $item->getItemsFull($basket->{details}->{basket_pkey},undef);
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

sub getBasketHeadFull {
    my ($self, $basketid, $detailsfields) = @_;

    my $basket_head = try {
        $self->pg->db->query(
            qq{
            SELECT basket_pkey, customers_pkey, customers.company ,name, registrationnumber, phone, homepage, address1, address2, address3 ,
                zipcode, city, company_mails, basketid, approved, status, payment, userid, reference, debt, discount
            FROM basket, customers WHERE basket_pkey = basket_fkey AND basketid = ? },
            ($basketid)
        )->hash;
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
        'basket',
        $basket_data,
            {
                basket_pkey => $basket_pkey
            }
    );
}

sub saveBasket{
    my($self, $data, $checkout) = @_;

    my $check = Order::Helper::Shoppingcart::Check::CartData->new();
    $data->{invoiceaddress} = $check->sanitizeAddress(
        $data->{invoiceaddress}
    ) if exists $data->{invoiceaddress};

    $data->{deliveryaddress} = $check->sanitizeAddress(
        $data->{deliveryaddress}
    ) if exists $data->{deliveryaddress};

    my $basket_pkey = $self->getBasketPkey($data->{basketid});
   
    eval{
            my $db = $self->pg->db;
			my $tx = $db->begin();

            my $basket_data;
            if($checkout){
                $basket_data->{status} = 'Checkout in progress';
                $basket_data->{approved} = 'true';
            }
            $data->{payment} = 'Invoice' unless $data->{payment};
            $basket_data->{payment} = $data->{payment};
            $basket_data->{userid} = $data->{userid};
            $basket_data->{company} = $data->{company};

            $db->update('basket',
                $basket_data
                ,{
                    basket_pkey => $basket_pkey
                }
            );
            
            my $address = Order::Helper::Shoppingcart::Address->new(db => $db);
            my $last_used = Order::Helper::Shoppingcart::LastUsedAddress->new(db => $db);
            if (exists $data->{invoiceaddress}){
                my $basket_addresses_fkey = $address->addressExists($basket_pkey, 'Invoice');
                if($basket_addresses_fkey){
                    $address->updateAddress($basket_addresses_fkey, $data->{invoiceaddress});
                }else{
                    $address->upsertAddress($basket_pkey, $data->{invoiceaddress},'Invoice') ;
                }
                $last_used->upsert_last_used_adresses(
                    $data->{userid}, $data->{company}, $data->{invoiceaddress}, 'Invoice'
                );
            }

             if (exists $data->{deliveryaddress}){
                my $basket_addresses_fkey = $address->addressExists($basket_pkey, 'Delivery');
                if($basket_addresses_fkey){
                    $address->updateAddress($basket_addresses_fkey, $data->{deliveryaddress});
                }else{
                    $address->upsertAddress($basket_pkey, $data->{deliveryaddress},'Delivery') ;
                }
                 $last_used->upsert_last_used_adresses(
                     $data->{userid}, $data->{company}, $data->{deliveryaddress}, 'Delivery'
                 );
            }
            $tx->commit();
	};

    $self->capture_message('','Shoppingcart::Cart::getBasketHead', (ref $self), (caller(0))[3], $@) if $@;
    say $@ if $@;
	return  {error => $@} if $@;
	return {basket_pkey => $basket_pkey, basketid => $data->{basketid}};
}

sub upsertItem{
    my($self, $data) = @_;

    say "[Order::Helper::Shoppingcart::Cart::upsertItem " . Dumper($data);
	my $basket_pkey = $self->getBasketPkey($data->{basketid});
    $data->{customer}->{debt} = 'ok'
        unless $data->{customer}->{debt};
    $data->{customer}->{discount} = 0
        unless $data->{customer}->{discount};
	eval{
        my $db = $self->pg->db;
        my $tx = $db->begin();

        if ($basket_pkey == 0){
            $basket_pkey = $db->insert(
                'basket',
                    {
                        basketid  => $data->{basketid},
                        userid    => $data->{userid},
                        company   => $data->{company},
                        debt      => $data->{customer}->{debt},
                        discount  => $data->{customer}->{discount},
                        reference => $data->{reference},
                    },
                    {
                        returning => 'basket_pkey'
                    }
            )->hash->{basket_pkey};

            $db->insert('customers',
                {
                    company            => $data->{customer}->{company}->{company},
                    name               => $data->{customer}->{company}->{name},
                    registrationnumber => $data->{customer}->{company}->{registrationnumber},
                    phone              => $data->{customer}->{company}->{phone},
                    homepage           => $data->{customer}->{company}->{homepage},
                    address1           => $data->{customer}->{address}->{address1},
                    address2           => $data->{customer}->{address}->{address2},
                    address3           => $data->{customer}->{address}->{address3},
                    zipcode            => $data->{customer}->{address}->{zipcode},
                    city               => $data->{customer}->{address}->{city},
                    company_mails      => $data->{customer}->{company_mails},
                    basket_fkey        => $basket_pkey,
                    externalids        => $data->{customer}->{externalids},
                    settings           => $data->{customer}->{settings},
                },
                {
                    on_conflict => [
                        ['basket_fkey'] => {
                            moddatetime => 'now()',
                            company => $data->{customer}->{company}->{company},
                            name => $data->{customer}->{company}->{name},
                            registrationnumber => $data->{customer}->{company}->{registrationnumber},
                            phone => $data->{customer}->{company}->{phone},
                            homepage => $data->{customer}->{company}->{homepage},
                            address1 => $data->{customer}->{address}->{address1},
                            address2 => $data->{customer}->{address}->{address2},
                            address3 => $data->{customer}->{address}->{address3},
                            zipcode => $data->{customer}->{address}->{zipcode},
                            city => $data->{customer}->{address}->{city},
                            company_mails => $data->{customer}->{company_mails},
                        }
                    ]
                }
            );

            my $last_used_address = Order::Helper::Shoppingcart::LastUsedAddress->new(
                pg     => $self->pg,
                config => $self->config,
            )->last_used_adresses(
                $data->{userid}, $data->{company}
            );

            if($last_used_address->{invoice}){
                my $address = Order::Helper::Shoppingcart::Address->new(db => $db);
                $address->upsertAddress($basket_pkey, $last_used_address->{invoice},'Invoice');
                $address->upsertAddress($basket_pkey, $last_used_address->{delivery},'Delivery');
            }

        }
        my $item = Order::Helper::Shoppingcart::Item->new(db => $db);
        $data->{basket_pkey} = $basket_pkey;
        $item->upsertItem($data);

        $tx->commit();
	};
    my $local = $@;
    $self->capture_message('','Shoppingcart::Cart::upsertItem', (ref $self), (caller(0))[3], $local) if $local;
    say $local if $local;
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
