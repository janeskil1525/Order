package Order::Model::PurchaseOrderHead;
use Mojo::Base 'Daje::Utils::Sentinelsender', -signatures;

use Mojo::JSON qw {decode_json };
use Order::Helper::Selectnames;
use Order::Model::OrderAddresses;
use Order::Helper::Selectnames;
use Order::Utils::Postgres::Columns;

use Try::Tiny;
use Data::Dumper;

has 'pg';
has 'db';

sub get_summary{
    my ($self, $order_head_pkey) = @_;

    my $orderhead = $self->load_order_head(
        $order_head_pkey
    );

    return "Order nr. " . $orderhead->{order_no} . "\n Order datum " . substr($orderhead->{orderdate},0,10);
}

sub get_company{
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select(
        'purchase_order_head', 'company',
        {
            purchase_order_head_pkey => $order_head_pkey
        }
    )->hash->{company};
}

sub get_userid{
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select(
        'purchase_order_head', 'userid',
        {
            purchase_order_head_pkey => $order_head_pkey
        }
    )->hash->{userid};
}

sub companies_fkey{
    my ($self, $order_head_pkey) = @_;

    my $result = $self->pg->db->select(
        'purchase_order_head', 'companies_fkey',
        {
            purchase_order_head_pkey => $order_head_pkey
        }
    );

    my $hash = 0;
    $hash = $result->hash->{companies_fkey} if $result->rows > 0;
    return $hash;
}

sub load_order_head{
    my ($self, $order_head_pkey) = @_;

    my $result =  $self->pg->db->select(
        'purchase_order_head', '*',
        {
            purchase_order_head_pkey => $order_head_pkey
        }
    );

    my $hash;
    $hash = $result->hash if $result->rows;
    return $hash;
}

sub load_order_head_p{
    my ($self, $order_head_pkey) = @_;

    return $self->pg->db->select_p(
        'purchase_order_head', '*',
        {
            purchase_order_head_pkey => $order_head_pkey
        }
    );
}

sub loadOpenOrderList ($self, $company, $grid_fields_list)  {

    my $selectnames = Order::Helper::Selectnames->new()->get_select_names($grid_fields_list);

    my $result = $self->pg->db->select(
        'purchase_order_head',
        $selectnames,
        {
            company => $company
        }
    );

    my $hash = ();
    $hash = $result->hashes if $result and $result->rows > 0;

    return $hash;
}

sub upsertHead{
    my ($self, $data, $ordertype, $item) = @_;

    my $supplier = $item->{supplier_data};
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
    $updates->{company} = $customer->{company}->{company};

    $updates->{userid} = $item->{supplier_data}->{sales_mails};
    $updates->{userid} = $item->{supplier_data}->{company_mails} unless $updates->{userid};


    $updates->{name} = $supplier->{company}->{name};
    $supplier->{company}->{registrationnumber} = '123456-1234' unless $supplier->{company}->{registrationnumber};
    $updates->{registrationnumber} = $supplier->{company}->{registrationnumber};
    $updates->{registrationnumber} = $updates->{registrationnumber} unless $updates->{registrationnumber};
    $updates->{phone} = $supplier->{company}->{phone};
    $updates->{homepage} = $supplier->{company}->{homepage};
    $updates->{homepage} = 'www.laga.se' unless $updates->{homepage};
    $updates->{address1} = $supplier->{address}->{address1};
    $updates->{address2} = $supplier->{address}->{address2};
    $updates->{address3} = $supplier->{address}->{address3};
    $updates->{zipcode} = $supplier->{address}->{zipcode};
    $updates->{city} = $supplier->{address}->{city};

    $updates->{company_mails} = $supplier->{company_mails};
    $updates->{company_mails} = $supplier->{sales_mails} unless $updates->{company_mails};
    $updates->{sales_mails} = $supplier->{sales_mails};
    $updates->{externalref} = $data->{basket}->{basket}->{basket_pkey};
    $updates->{supplier} = $supplier->{company}->{company};

    my $order_head_pkey = try {
        my $purchase_order_head_pkey = $db->insert(
            'purchase_order_head', $updates,
            {
                on_conflict => \[' (order_no) Do update set moddatetime = ?', 'now()'],
                returning => 'purchase_order_head_pkey'
            }
        )->hash->{purchase_order_head_pkey};

        return $purchase_order_head_pkey;
    } catch {
        $self->capture_message("[Daje::Model::OrderHead::upsertHead] " . $_);
        say "[Order::Model::PurchaseOrderHead::upsertHead] " . $_;
    };

    return $order_head_pkey;
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
        say "[Order::Model::PurchaseOrderHead:setCustomerAddresses] " . $_;
    };
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

    return  $db->query(qq{ SELECT nextval('orderno') as orderno })->hash->{orderno};
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
