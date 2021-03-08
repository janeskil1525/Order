package Order::Helper::Shoppingcart::Address;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures;

use Try::Tiny;
#use Order::Utils::Addresses::Company;

has 'pg';
has 'db';

sub dropAddresses ($self, $basket_pkey) {
	
	my $addresses = $self->pg->db->select(
					['basket_addresses_basket',
					['basket_addresses',
						'basket_addresses_pkey' => 'basket_addresses_fkey']],
					['basket_addresses_pkey', 'basket_addresses_basket_pkey'],
					{				
						'basket_fkey' => $basket_pkey
				})->hashes;
	
	my $length = $addresses->size;
	
	for(my $i = 0; $i < $length; $i++){
		$self->pg->db->delete('basket_addresses_basket',
							  {'basket_addresses_basket_pkey' => $addresses->[$i]->{basket_addresses_basket_pkey}}
		);
		$self->pg->db->delete('basket_addresses',
							  {'basket_addresses_pkey' => $addresses->[$i]->{basket_addresses_pkey}}
		);
	}
	return 1;
}

sub loadAddress ($self, $basket_pkey, $type, $addressfields) {
	
	my $result = try{
		$self->pg->db->select(
			['basket_addresses_basket',
			['basket_addresses', 'basket_addresses_pkey' => 'basket_addresses_fkey']],
			$addressfields,
			{
				'address_type' => $type,
				'basket_fkey' => $basket_pkey
			})->hash;
	}catch{
		$self->capture_message("[Shoppingcart::Address::loadAddress] " . $_);
		say $_;
		return ;
	};
	
	return $result;
}

sub updateAddress ($self, $basket_addresses_fkey, $address, $type)  {

	my $db;
	if($self->db){
		$db = $self->db
	} else {
		$db = $self->pg->db;
	}

	$db->update('basket_addresses',{
		name => $address->{name},
		address1 => $address->{address1},
		address2 => $address->{address2},
		zipcode => $address->{zipcode},
		city => $address->{city},
		country => $address->{country}
	},{
		basket_addresses_pkey => $basket_addresses_fkey
	});
		
}

sub upsertAddress ($self, $basket_pkey, $address, $type) {
	
	my $db;
	if($self->db) {
		$db = $self->db;
	} else {
		$db = $self->pg->db;
	}
	my $basket_addresses_pkey = $db->insert('basket_addresses',{
		name => $address->{name},
		address1 => $address->{address1},
		address2 => $address->{address2},
		zipcode => $address->{zipcode},
		city => $address->{city},
		country => $address->{country}
	 },{
		returning => 'basket_addresses_pkey'
		})->hash->{basket_addresses_pkey};
	
	my $result = try {
		$db->insert('basket_addresses_basket',{
			address_type => $type,
			basket_fkey => $basket_pkey,
			basket_addresses_fkey => $basket_addresses_pkey
			},{on_conflict => undef}
		);
	}catch{
		$self->capture_message("[Shoppingcart::Address::upsertAddress] " . $_);
		say $_;
	};
	return $result;
}

sub addressExists ($self, $basket_pkey, $type) {

	my $db;
	if($self->db){
		$db = $self->db
	} else {
		$db = $self->pg->db;
	}
	my $basket_addresses_fkey = $db->select(
						'basket_addresses_basket',
						  ['basket_addresses_fkey'],
						  {'basket_fkey' => $basket_pkey,
						   address_type => $type
						   })->hash;
	$basket_addresses_fkey->{basket_addresses_fkey} = 0
		unless exists $basket_addresses_fkey->{basket_addresses_fkey};
		
	return $basket_addresses_fkey->{basket_addresses_fkey} ;
}

1;
