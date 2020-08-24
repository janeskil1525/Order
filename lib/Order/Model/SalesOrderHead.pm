package Order::Model::SalesOrderHead;
use Mojo::Base 'Daje::Utils::Sentinelsender';


use Mojo::JSON qw {decode_json };
use Order::Helper::Selectnames;
use Order::Model::OrderAddresses;
use Daje::Model::OrderCompanies;
use Daje::Utils::Postgres::Columns;
use Daje::Utils::User;
use Try::Tiny;
use Data::Dumper;

has 'pg';

sub companies_fkey{
    my ($self, $sales_order_head_pkey) = @_;

    return $self->pg->db->select(
        'sales_order_head', 'companies_fkey',
        {
            sales_order_head_pkey => $sales_order_head_pkey
        }
    )->hash->{companies_fkey};
}

sub load_order_head{
    my ($self, $sales_order_head_pkey) = @_;

    return $self->pg->db->select(
        'sales_order_head', '*',
        {
            sales_order_head_pkey => $sales_order_head_pkey
        }
    );
}

sub load_order_head_p{
    my ($self, $sales_order_head_pkey) = @_;

    return $self->pg->db->select_p(
        'sales_order_head', '*',
        {
            sales_order_head_pkey => $sales_order_head_pkey
        }
    );
}

sub loadOpenOrderList{
    my ($self, $company, $ordertype, $grid_fields_list) = @_;

    my $selectnames = Daje::Utils::Selectnames->new()->get_select_names($grid_fields_list);

    return $self->pg->db->select(
        'sales_order_head',
        $selectnames,
        {
            order_type => $ordertype,
            company => $company
        })->hashes;
}

sub upsertHead{
    my ($self, $data, $ordertype, $supplier) = @_;

    $data->{order_no} = $self->getOrderNo()
        unless exists $data->{order_no} and $data->{order_no} > 0;

    my $updates;
    $updates->{order_type} = $ordertype;
    $updates->{order_no} = $data->{order_no};
    $updates->{company} = $supplier;
    $updates->{userid} = $data->{details}->{company_mails};
    $updates->{name} = $data->{details}->{name};
    $updates->{registrationnumber} = $data->{details}->{registrationnumber};
    $updates->{homepage} = $data->{details}->{homepage};
    $updates->{phone} = $data->{details}->{phone};
    $updates->{address1} = $data->{details}->{address1};
    $updates->{address2} = $data->{details}->{address2};
    $updates->{address3} = $data->{details}->{address3};
    $updates->{zipcode} = $data->{details}->{zipcode};
    $updates->{city} = $data->{details}->{city};
    $updates->{externalref} = $data->{details}->{basketid};
    $updates->{debt} = $data->{details}->{debt};
    $updates->{customer} = $data->{details}->{company};

    my $order_head_pkey = try{
        $self->pg->db->insert(
            'sales_order_head', $updates,
            {
                on_conflict => \[' (order_no) Do update set moddatetime = ?', 'now()'],
                returning => 'sales_order_head_pkey'
            }
        )->hash->{sales_order_head_pkey};
    }catch{
        say "[Daje::Model::OrderHead::upsertHead] " . $_;
        $self->capture_message("[Daje::Model::OrderHead::upsertHead] " . $_);
    };

    return $order_head_pkey;
}


sub getSalesUser{
    my ($self, $suppliers_pkey) = @_;

    my $users_pkey = Daje::Utils::User->new(
        pg => $self->pg
    )->getSalesUser($suppliers_pkey);
    return $users_pkey;
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
