package Order::Model::SalesOrderHead;
use Mojo::Base 'Daje::Utils::Sentinelsender';


use Mojo::JSON qw {decode_json };
use Order::Helper::Selectnames;
use Order::Model::OrderAddresses;
use Order::Model::OrderCompanies;
use Order::Utils::Postgres::Columns;
use Order::Utils::User;
use Try::Tiny;
use Data::Dumper;

has 'pg';
has 'db';

sub get_summary{
    my ($self, $order_head_pkey) = @_;

    my $orderhead = $self->load_order_head(
        $order_head_pkey
    )->hash;

    return "Order nr. " . $orderhead->{order_no} . "\n Order datum " . substr($orderhead->{orderdate},0,10);
}

sub get_company{
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select(
        'sales_order_head', 'company',
        {
            sales_order_head_pkey => $order_head_pkey
        }
    )->hash->{company};
}

sub get_userid {
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select(
        'sales_order_head', 'userid',
        {
            sales_order_head_pkey => $order_head_pkey
        }
    )->hash->{userid};
}

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
    my ($self, $data, $ordertype, $item) = @_;

    my $db;
    $item->{sales_mails} = 'jan@daje.work'
        unless $item->{sales_mails};
    if($self->db) {
        $db = $self->db;
    } else {
        $db = $self->pg->db;
    }
    $data->{order_no} = $self->getOrderNo()
        unless exists $data->{order_no} and $data->{order_no} > 0;

    my $updates;
    $updates->{order_type} = $ordertype;
    $updates->{order_no} = $data->{order_no};
    $updates->{company} = $item->{supplier};
    $updates->{userid} = $item->{sales_mails};
    $updates->{userid} = $item->{company_mails} unless $updates->{userid};

    $updates->{name} = $item->{name};
    $updates->{registrationnumber} = $data->{details}->{registrationnumber};
    $updates->{homepage} = $data->{details}->{homepage};
    $updates->{phone} = $data->{details}->{phone};
    $updates->{address1} = $data->{details}->{address1};
    $updates->{address2} = $data->{details}->{address2};
    $updates->{address3} = $data->{details}->{address3};
    $updates->{zipcode} = $data->{details}->{zipcode};
    $updates->{city} = $data->{details}->{city};
    $updates->{company_mails} = $item->{company_mails};
    $updates->{sales_mails} = $item->{sales_mails};
    $updates->{externalref} = $data->{details}->{basketid};
    $updates->{debt} = $data->{details}->{debt};
    $updates->{customer} = $data->{details}->{company};
    $updates->{export_to} = 'orion';
    $updates->{export_status} = 'new';

    my $order_head_pkey = try{
        $db->insert(
            'sales_order_head', $updates,
            {
                on_conflict => \[' (order_no) Do update set moddatetime = ?', 'now()'],
                returning => 'sales_order_head_pkey'
            }
        )->hash->{sales_order_head_pkey};
    }catch{
        say "[DOrder::Model::SalesOrderHead::upsertHead] " . $_;
        $self->capture_message(
            '', 'Order::Model::SalesOrderHead::upsertHead', (ref $self), (caller(0))[3], $_
        );
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

    my $db;
    if($self->db) {
        $db = $self->db;
    } else {
        $db = $self->pg->db;
    }

    return $db->query(qq{ SELECT nextval('orderno') as orderno })->hash->{orderno};
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    my $fields;
    ($data, $fields) = Order::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->set_setdefault_data($data, 'order_head');

    return $data, $fields;
}

sub get_table_column_names {
    my $self = shift;

    my $fields;
    $fields = Order::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->get_table_column_names('order_head');

    return $fields;
}
1;
