package Order::Helper::Rfqs;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Model::Rfqs;
use Mojo::JSON qw{decode_json encode_json};
use Mojo::Promise;
use Daje::Model::Companies;
use Daje::Model::User;
use Data::Dumper;

our $VERSION = '0.2.2';

has 'pg';
has 'minion';

sub register {
    my ($self, $app) = @_;

    $self->pg($app->pg);

    $app->minion->add_task(send_rfq => \&_send_rfq);
    $self->minion($app->minion);

    $app->helper(rfqs => sub {$self});
}

sub list_all_rfqs_from_status_p{
    my ($self, $companies_fkey, $rfqstatus) = @_;

    return Daje::Model::Rfqs->new(
        pg => $self->pg
    )->list_all_rfqs_from_status_p($companies_fkey, $rfqstatus);
}

sub load_rfq_p{
    my ($self, $rfqs_pkey) = @_;

    return Daje::Model::Rfqs->new(
        pg => $self->pg
    )->load_rfq_p($rfqs_pkey);
}

sub save_rfq_p{
    my ($self, $data) = @_;

    return Daje::Model::Rfqs->new(
        pg => $self->pg
    )->save_rfq_p($data);
}

sub send_rfq_p{
    my ($self, $data) = @_;


    my $rfq_p = Daje::Model::Rfqs->new(
        pg => $self->pg
    )->save_rfq_p($data);

    my $customer_p = Daje::Model::Companies->new(
        pg => $self->pg
    )->load_company_only_p(
        $data->{companies_fkey}
    );

    my $supplier_p = Daje::Model::Companies->new(
        pg => $self->pg
    )->load_company_only_p(
        $data->{supplier_fkey}
    );

    my $user_p = Daje::Model::User->new(
        pg => $self->pg
    )->load_user_p(
        $data->{users_fkey}
    );

    return Mojo::Promise->all($rfq_p, $customer_p, $user_p, $supplier_p)->then(sub{
        my ($rfq, $customer, $user, $supplier) = @_;

        my $rfq_no = $rfq->[0]->hash->{rfq_no};

        $rfq->[0]->finish();

        my $data->{rfq} = Daje::Model::Rfqs->new(
            pg => $self->pg
        )->load_from_rfqno($rfq_no)->hash;

        $data->{type} = 'rfq_sent';
        $data->{customer} = $customer->[0]->hash;
        $customer->[0]->finish();
        $data->{customer_user} = $user->[0]->hash;
        $user->[0]->finish();
        $data->{supplier} = $supplier->[0]->hash;
        $supplier->[0]->finish;

        my $json_result = encode_json($data);

        $self->minion->enqueue('send_rfq' => [$json_result] => {priority => 0});

        return $rfq_no;
    })->catch(sub{
        my $err = shift;

        say $err;
    });
}

sub set_setdefault_data{
    my ($self, $data) = @_;

    return Daje::Model::Rfqs->new(
        pg => $self->pg
    )->set_setdefault_data($data);
}

sub _send_rfq{
    my($job, $import) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

    my $data = decode_json $import;
    $year = "20$year";
    $data->{sentat} = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year, $mon, $mday, $hour, $min, $sec);
    $data->{messagetype} = 'rfq_sent';

    my $rfq_json = encode_json($data);
    $job->app->minion->enqueue('create_message' => [$rfq_json] );

    $job->app->rfqs->set_sent_at($data);

    $job->finish({ status => "success"});
}

sub set_sent_at{
    my ($self, $data) = @_;

    return Daje::Model::Rfqs->new(
        pg => $self->pg
    )->set_sent_at($data);
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Rfqs - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Rfqs');

  # Mojolicious::Lite
  plugin 'Rfqs';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Rfqs> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Rfqs> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut


1;