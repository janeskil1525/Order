package Order::Model::Rfqs;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Try::Tiny;
use Data::Dumper;

our $VERSION = '0.3.6';

has 'pg';


sub list_all_rfqs_from_status_p{
    my ($self, $companies_fkey, $rfqstatus) = @_;

    $rfqstatus = 'NEW' unless $rfqstatus;

    return $self->pg->db->query_p(
        qq{SELECT rfqs_pkey, rfq_no, rfqstatus, requestdate, regplate, note,
         (SELECT userid || ' ' || username FROM users WHERE users_pkey = users_fkey) as user,
          (SELECT name FROM companies WHERE companies_pkey = companies_fkey) as customer,
           (SELECT name FROM companies WHERE companies_pkey = supplier_fkey) as supplier
           FROM rfqs WHERE rfqstatus = ? AND companies_fkey = ?},
        ($rfqstatus, $companies_fkey)
    );
}

sub save_rfq_p{
    my ($self, $data) = @_;

    $data->{rfq_no} = $self->getRfqNo() unless $data->{rfq_no};

    return $self->pg->db->query_p(qq{
        INSERT INTO rfqs
            (rfq_no, rfqstatus, regplate, note, users_fkey, companies_fkey, supplier_fkey)
        VALUES (?,?,?,?,?,?,?)
        ON CONFLICT (rfq_no)
            DO UPDATE SET moddatetime = now(), rfqstatus = ?, regplate = ?, note = ?, sent = ?
        RETURNING rfq_no
    },
        (
            $data->{rfq_no},
            $data->{rfqstatus},
            $data->{regplate},
            $data->{note},
            $data->{users_fkey},
            $data->{companies_fkey},
            $data->{supplier_fkey},
            $data->{rfqstatus},
            $data->{regplate},
            $data->{note},
            $data->{sent}
        )
    );
}

sub load_rfq_p{
    my ($self, $rfqs_pkey) = @_;

    return $self->pg->db->select_p(
        'rfqs',
        '*',
        {
            'rfqs_pkey' => $rfqs_pkey
        }
    );
}

sub load_from_rfqno{
    my ($self, $rfq_no) = @_;

    return $self->pg->db->select(
        'rfqs',
        '*',
        {
            'rfq_no' => $rfq_no
        }
    );
}


sub getRfqNo{
    my $self = shift;

    return try {
        $self->pg->db->query(qq{ SELECT nextval('rfqno') as rfq_no })->hash->{rfq_no};
    }catch{
        $self->capture_message("[Daje::Model::Rfqs::getRfqNo] " . $_);
        say $_;
    };
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    my $fields;
    ($data, $fields) = Daje::Utils::Postgres::Columns->new(
        pg => $self->pg
    )->set_setdefault_data($data, 'rfqs');

    return $data, $fields;
}

sub set_sent_at{
    my ($self, $data) = @_;

    return $self->pg->db->update(
        'rfqs',
        {
            sentat => $data->{sentat},
            sent   => 'true',
        },
        {
            rfqs_pkey => $data->{rfqs_pkey}
        }
    );
}
1;


1;