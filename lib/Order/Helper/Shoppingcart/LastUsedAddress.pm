package Order::Helper::Shoppingcart::LastUsedAddress;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures;

use Mojo::UserAgent;
use Mojo::JSON;
use Try::Tiny;
use Data::Dumper;

has 'pg';
has 'db';
has 'config';

sub last_used_adresses ($self, $userid, $company) {

    my $last_used = $self->load_last_used_addresses($userid, $company);

    if(not $last_used) {
        $self->get_default_addresses($userid, $company);
        $last_used = $self->load_last_used_addresses($userid, $company);
    }

    return $last_used;
}

sub load_last_used_addresses ($self, $userid, $company) {

    my $invoice = $self->pg->db->select(
        'last_used_basket_addresses',
        undef,
            {
                userid       => $userid,
                company      => $company,
                address_type => 'Invoice'
            }
    );

    my $delivery = $self->pg->db->select(
        'last_used_basket_addresses',
        undef,
        {
            userid       => $userid,
            company      => $company,
            address_type => 'Delivery'
        }
    );

    my $result;
    if ($delivery->rows > 0 and $invoice->rows > 0) {
        $result->{invoice} = $invoice->hash;
        $result->{delivery} = $delivery->hash;
    }

    return $result;
}

sub get_default_addresses ($self, $userid, $company) {

    my $ua = Mojo::UserAgent->new();

    my $key = $self->config->{webshop}->{key};
    my $url = $self->config->{webshop}->{address} . '/api/v1/company/default/address/' . $company;
    my $value = try {
        return $ua->get(
            $url => {
                Accept => '*/*', 'X-Token-Check' => $key
            }
        )->result->json;
    } catch {
        $self->capture_message('','Order', (ref $self), (caller(0))[3], "get_default_addresses " . $_);
        say "[Order::Helper::Shoppingcart::LastUsedAddress::get_default_addresses] " . $_;
        return ;
    };

    if($value) {
        $self->upsert_last_used_adresses($userid, $company, $value, 'Invoice');
        $self->upsert_last_used_adresses($userid, $company, $value, 'Delivery');
    }

}

sub upsert_last_used_adresses ($self, $userid, $company, $address, $type) {

    my $db;
    if($self->db) {
        $db = $self->db;
    } else {
        $db = $self->pg->db;
    }

    my $result = try {
        my $return = $db->insert(
            'last_used_basket_addresses',
            {
                name         => $address->{name},
                address1     => $address->{address1},
                address2     => $address->{address2},
                address3     => $address->{address3},
                city         => $address->{city},
                zipcode      => $address->{zipcode},
                country      => $address->{country},
                userid       => $userid,
                company      => $company,
                address_type => $type,
            },
            {
                on_conflict => [
                    [ 'userid', 'company', 'address_type' ] => {
                        name        => $address->{name},
                        address1    => $address->{address1},
                        address2    => $address->{address2},
                        address3    => $address->{address3},
                        city        => $address->{city},
                        zipcode     => $address->{zipcode},
                        country     => $address->{country},
                        moddatetime => 'now()',
                    }
                ]
            }
        );
        return 1;
    } catch {
        $self->capture_message('','Order', (ref $self), (caller(0))[3], "upsert_last_used_adresses " . $_);
        say "[Order::Helper::Shoppingcart::LastUsedAddress::upsert_last_used_adresses] " .  $_;
        return 0;
    };

    return $result;
}
1;