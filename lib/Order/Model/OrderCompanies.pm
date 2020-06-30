package Daje::Model::OrderCompanies;
use Mojo::Base 'Daje::Utils::Sentry::Raven';

use Try::Tiny;

has 'pg';

sub load_order_companies_p{
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select_p(
        ['order_companies_order',['companies',
            'companies.companies_pkey' => 'order_companies_order.companies_fkey']
        ],
        '*',
        {
            order_head_fkey => $order_head_pkey
        }
    );
}

sub setOrderCompanies{
    my ($self, $order_head_pkey, $companies_pkey, $type) = @_;

    try {
        $self->pg->db->insert('order_companies_order',
            {
                order_head_fkey => $order_head_pkey,
                companies_fkey => $companies_pkey,
                relation_type => $type,
            },{
                on_conflict => undef,
            });

    }catch{
        $self->capture_message("[Daje::Model::OrderAddresses::setSupplierAddresses] " . $_);
        say $_
    };
}

1;
