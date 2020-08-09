package Shoppingcart::Check::CartData;

use Mojo::Base -base;


sub sanitizeAddress{
	my ($self, $address) = @_;
	
	$address->{address1} = '' unless exists $address->{address1};
    $address->{address2} = '' unless exists $address->{address2};
    $address->{address3} = '' unless exists $address->{address3};
    $address->{city} = '' unless exists $address->{city};
    $address->{zipcode} = '' unless exists $address->{zipcode};
    $address->{country} = '' unless exists $address->{country};
	
	return $address
}


1;