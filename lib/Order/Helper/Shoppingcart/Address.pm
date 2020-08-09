package Shoppingcart::Address;
use Mojo::Base 'Daje::Utils::Sentry::Raven';

use Try::Tiny;
use Daje::Utils::Addresses::Company;

has 'pg';

sub dropAddresses{
	my ($self, $basket_pkey) = @_;
	
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

sub loadAddress{
	my ($self, $basket_pkey, $type, $addressfields, $company_pkey) = @_;
	
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
	
	if($type eq 'Invoice'){
		$result = $self->default_address($company_pkey) unless $result;
	}
	
	return $result;
}

sub default_address{
	my ($self, $company_pkey) = @_;

	return Daje::Utils::Addresses::Company->new(pg => $self->pg)->load_address($company_pkey);
}

sub updateAddress{
	my ($self, $basket_addresses_fkey, $address, $type) = @_;
	
	$self->pg->db->update('basket_addresses',{
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

sub upsertAddress{
	my ($self, $basket_pkey, $address, $type) = @_;
	
	
	my $basket_addresses_pkey = $self->pg->db->insert('basket_addresses',{
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
		$self->pg->db->insert('basket_addresses_basket',{
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

sub addressExists{
	my ($self, $basket_pkey, $type) = @_;
	
	my $basket_addresses_fkey = $self->pg->db->select(
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
