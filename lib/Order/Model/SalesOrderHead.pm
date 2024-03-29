package Order::Model::SalesOrderHead;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures, -async_await;


use Mojo::JSON qw {decode_json from_json encode_json};
use Order::Helper::Selectnames;
use Order::Utils::Postgres::Columns;
use Order::Utils::User;
use Try::Tiny;
use Data::Dumper;

has 'pg';
has 'db';


sub set_export_status {
    my ($self, $sales_order_head_pkey, $status) = @_;

    return $self->pg->db->update(
        'sales_order_head',
        {
            export_status => $status,
        },{
            sales_order_head_pkey => $sales_order_head_pkey,
        }
    );
}

async sub set_export_status_async {
    my ($self, $sales_order_head_pkey, $status) = @_;

    return $self->pg->db->update(
        'sales_order_head',
        {
            export_status => $status,
        },{
        sales_order_head_pkey => $sales_order_head_pkey,
    }
    );
}

sub get_order_for_export {
    my ($self, $export_to) = @_;

    my $order_head = $self->pg->db->select(
        'sales_order_head', 'sales_order_head_pkey',
        {
            export_to     => $export_to,
            export_status => 'new',
        },
        {
            limit => 1
        }
    );

    my $hash;
    my $sales_order_head_pkey = 0;
    $hash = $order_head->hash if $order_head->rows() > 0;
    if($hash){
        $sales_order_head_pkey = $hash->{sales_order_head_pkey};
    }
    return $sales_order_head_pkey;
}

sub get_summary{
    my ($self, $order_head_pkey) = @_;

    my $orderhead = $self->load_order_head(
        $order_head_pkey
    );

    return "Order nr. " . $orderhead->{order_no} . "\n Order datum " . substr($orderhead->{orderdate},0,10)
        if $orderhead;

    return;
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

    my $result = $self->pg->db->select(
        'sales_order_head', 'companies_fkey',
        {
            sales_order_head_pkey => $sales_order_head_pkey
        }
    );
    my $hash = 0;
    $hash = $result->hash->{companies_fkey} if $result->rows;
    return $hash;
}

sub load_order_head ($self, $sales_order_head_pkey) {

    my $result = $self->pg->db->select(
        'sales_order_head', '*',
        {
            sales_order_head_pkey => $sales_order_head_pkey
        }
    );

    my $hash;
    $hash = $result->hash if $result->rows() > 0;
    return $hash;
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

sub loadOpenOrderList ($self, $company, $grid_fields_list) {

    my $selectnames = Order::Helper::Selectnames->new()->get_select_names($grid_fields_list);

    my $orders = try {
        $self->pg->db->select(
            'sales_order_head',
            $selectnames,
            {
                company => $company
            }
        );
    } catch {
        say $_;
    };

    my $hash = ();
    $hash = $orders->hashes if $orders and $orders->rows() > 0;

    return $hash;
}

async sub loadExportOrderList ($self, $system) {

    my $orders = try {
        $self->pg->db->select(
            'sales_order_head',
            undef,
            {
                export_to     => $system,
                export_status => 'new'
            }
        );
    } catch {
        say $_;
    };

    my $hash = ();
    $hash = $orders->hashes if $orders and $orders->rows() > 0;

    return $hash;
}

sub upsertHead{
    my ($self, $data, $ordertype, $item) = @_;

    my $customer = $data->{basket}->{customer};
    my $db;
    $item->{supplier_data}->{sales_mails} = 'jan@daje.work'
        unless $item->{supplier_data}->{sales_mails};
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
    $updates->{userid} = $item->{supplier_data}->{sales_mails};
    $updates->{userid} = $item->{supplier_data}->{company_mails} unless $updates->{userid};

    $updates->{name} = $customer->{company}->{name};
    $updates->{registrationnumber} = $customer->{company}->{registrationnumber};
    $updates->{homepage} = $customer->{company}->{homepage};
    $updates->{phone} = $customer->{company}->{phone};
    $updates->{address1} = $customer->{invoiceaddress}->{address1};
    $updates->{address2} = $customer->{invoiceaddress}->{address2};
    $updates->{address3} = $customer->{invoiceaddress}->{address3};
    $updates->{zipcode} = $customer->{invoiceaddress}->{zipcode};
    $updates->{city} = $customer->{invoiceaddress}->{city};
    $updates->{company_mails} = $item->{company_mails} ;
    $updates->{company_mails} = $updates->{userid} unless $updates->{company_mails};

    $updates->{sales_mails} = $item->{sales_mails};
    $updates->{sales_mails} = $updates->{userid} unless $updates->{sales_mails};

    $updates->{externalref} = $data->{basket}->{basket}->{basket_pkey};
    $updates->{debt} = 0;
    $updates->{customer} = $customer->{company}->{company};
    $updates->{export_to} = '';
    $updates->{externalids} = $data->{basket}->{basket}->{basket_pkey};
    my $exportdest = $item->{supplier_data};
    if(exists $exportdest->{settings}->{orion} and $exportdest->{settings}->{orion}){
        $updates->{export_to} = 'orion';
    }
    $updates->{export_status} = 'new';
    $updates->{settings} = encode_json($item->{supplier_data}->{settings});


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
