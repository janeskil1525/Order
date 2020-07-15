package Order::Model::OrderHead;
use Mojo::Base 'Daje::Utils::Sentry::Raven';

use Mojo::JSON qw {decode_json };
use Daje::Utils::Selectnames;
use Daje::Model::OrderAddresses;
use Daje::Model::OrderCompanies;
use Daje::Utils::Postgres::Columns;
use Daje::Utils::User;
use Try::Tiny;
use Data::Dumper;

has 'pg';

sub companies_fkey{
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select(
        'order_head', 'companies_fkey',
        {
            order_head_pkey => $order_head_pkey
        }
    )->hash->{companies_fkey};
}

sub load_order_head{
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select(
        'order_head', '*',
        {
            order_head_pkey => $order_head_pkey
        }
    );
}

sub load_order_head_p{
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select_p(
        'order_head', '*',
        {
            order_head_pkey => $order_head_pkey
        }
    );
}

sub loadOpenOrderList{
    my ($self, $companies_fkey, $ordertype, $grid_fields_list) = @_;

    my $selectnames = Daje::Utils::Selectnames->new()->get_select_names($grid_fields_list);

    return $self->pg->db->select(
        ['order_head',
            ['users', users_pkey => 'users_fkey'],
            ['companies', companies_pkey => 'companies_fkey']],
        $selectnames,
        {
            order_type => $ordertype,
            companies_fkey => $companies_fkey
        })->hashes;
}

sub upsertHead{
    my ($self, $data, $ordertype, $suppliers_pkey) = @_;

    $data->{order_no} = $self->getOrderNo()
        unless exists $data->{order_no} and $data->{order_no} > 0;

    my $updates;
    $updates->{order_type} = $ordertype;
    $updates->{order_no} = $data->{order_no};

    if($ordertype == 1){
        $updates->{companies_fkey} = $data->{details}->{companies_fkey};
        $updates->{users_fkey} = $data->{details}->{users_fkey};
    }elsif($ordertype == 2){
        $updates->{companies_fkey} = $suppliers_pkey;
        $updates->{users_fkey} = $self->getSalesUser($suppliers_pkey);
    }


    my $order_head_pkey = try{
        $self->pg->db->insert(
            'order_head', $updates,
            {
                on_conflict => \[' (order_no) Do update set moddatetime = ?', 'now()'],
                returning => 'order_head_pkey'
            }
        )->hash->{order_head_pkey};
    }catch{
        $self->capture_message("[Daje::Model::OrderHead::upsertHead] " . $_);
        say "[Daje::Model::OrderHead::upsertHead] " . @_;
    };

    if($ordertype == 1){
        $self->connectBasket($data, $order_head_pkey);
        $self->setSupplierAddresses($order_head_pkey, $suppliers_pkey);
        $self->setOrderCompanies($order_head_pkey, $suppliers_pkey, 'Supplier');
    }elsif($ordertype == 2){
        $self->setCustomerAddresses($order_head_pkey, $data);
        $self->setOrderCompanies($order_head_pkey, $data->{details}->{companies_fkey},'Customer');
    }
    return $order_head_pkey;
}

sub setOrderCompanies{
    my ($self, $order_head_pkey, $companies_pkey, $type) = @_;

    try{
        Daje::Model::OrderCompanies->new(
            pg => $self->pg
        )->setOrderCompanies(
            $order_head_pkey, $companies_pkey, $type
        );
    }catch{
        $self->capture_message("[Daje::Model::OrderHead::setOrderCompanies] " . $_);
        say "[Daje::Model::OrderHead::setOrderCompanies] " . @_;
    };
}

sub setSupplierAddresses{
    my ($self, $order_head_pkey, $suppliers_pkey) = @_;

    Daje::Model::OrderAddresses->new(
        pg => $self->pg
    )->setSupplierAddresses($order_head_pkey, $suppliers_pkey);

}
sub setCustomerAddresses{
    my ($self, $order_head_pkey, $data) = @_;

    try{
        Daje::Model::OrderAddresses->new(
            pg => $self->pg
        )->setCustomerAddresses($order_head_pkey, $data);
    }catch{
        $self->capture_message("[Daje::Model::OrderHead::setCustomerAddresses] " . $_);
        say "[Daje::Model::OrderHead::setCustomerAddresses] " . $_;
    };
}

sub getSalesUser{
    my ($self, $suppliers_pkey) = @_;

    my $users_pkey = Daje::Utils::User->new(
        pg => $self->pg
    )->getSalesUser($suppliers_pkey);
    return $users_pkey;
}

sub connectBasket{
    my ($self, $data, $order_head_pkey) = @_;

    if(exists $data->{details}->{basket_pkey}){

        $self->pg->db->insert('order_basket',
            {
                order_head_fkey => $order_head_pkey,
                basket_fkey => $data->{details}->{basket_pkey},
            },{
                on_conflict => undef,
            });
    }
}

sub getOrderNo{
    my $self = shift;

    return try {
        $self->pg->db->query(qq{ SELECT nextval('orderno') as orderno })->hash->{orderno};
    }catch{
        $self->capture_message("[Daje::Model::OrderHead::getOrderNo] " . $_);
        say $_;
    };
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    my $fields;
    ($data, $fields) = Daje::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->set_setdefault_data($data, 'order_head');

    return $data, $fields;
}

sub get_table_column_names {
    my $self = shift;

    my $fields;
    $fields = Daje::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->get_table_column_names('order_head');

    return $fields;
}
1;
