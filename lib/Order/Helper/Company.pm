package Order::Utils::Addresses::Company;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Daje::Model::Addresses;

use Try::Tiny;

has 'pg';

sub load_address{
    my ($self, $company_pkey, $type) = @_;

    $type = 'invoice' unless $type;

    my $result = try {
        $self->pg->db->select([ 'addresses',
            [ 'addresses_company', addresses_fkey => 'addresses_pkey' ]],
            [ 'addresses_pkey', 'name', 'address1', 'address2', 'address3', 'city', 'zipcode', 'country', 'address_type' ],
            { address_type => $type, companies_fkey => $company_pkey })->hash;
    }catch{
        $self->capture_message("[Daje::Model::Addresses::load_address] " . $_);
        say $_;
    };

    return $result;
}

sub load_addresses_p{
    my ($self, $company_pkey) = @_;

    my $result = try {
        $self->pg->db->select_p([ 'addresses',
            [ 'addresses_company', addresses_fkey => 'addresses_pkey' ]],
            [ 'addresses_pkey', 'name', 'address1', 'address2', 'address3', 'city', 'zipcode', 'country', 'address_type' ],
            { companies_fkey => $company_pkey });
    }catch{
        $self->capture_message("[Daje::Model::Addresses::load_addresses_p] " . $_);
        say $_;
    };

    return $result;
}

sub save_company_address_p{
    my ($self, $data) = @_;

    return Daje::Model::Addresses->new(
        pg => $self->pg
    )->save_address_p($data)->then(sub{
        my $result = shift;

        my $addresses_pkey = $result->hash->{addresses_pkey};
        $result->finish;

        $self->pg->db->query(
            "INSERT INTO addresses_company
                    (companies_fkey, addresses_fkey, address_type)
            VALUES (?,?,?)
                ON CONFLICT (companies_fkey, addresses_fkey, address_type)
            DO NOTHING ",
            (
                $data->{companies_pkey},
                $addresses_pkey,
                $data->{address_type}
            )
        );

    });
}



1;
