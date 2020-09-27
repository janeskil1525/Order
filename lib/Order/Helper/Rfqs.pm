package Order::Helper::Rfqs;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Order::Model::Rfqs;
use Order::Helper::Rfqs::Messenger;
use Daje::Utils::Sentinelsender;

use Mojo::JSON qw{decode_json encode_json};
use Mojo::Promise;
use Data::Dumper;
use Try::Tiny;

has 'pg';
has 'minion';

sub init {
    my ($self, $minion) = @_;

    $minion->minion->add_task(send_rfq => \&_send_rfq);
}

sub list_all_rfqs_from_status_p{
    my ($self, $companies_fkey, $rfqstatus) = @_;

    return Order::Model::Rfqs->new(
        pg => $self->pg
    )->list_all_rfqs_from_status_p($companies_fkey, $rfqstatus);
}

sub load_rfq_p{
    my ($self, $rfqs_pkey) = @_;

    return Order::Model::Rfqs->new(
        pg => $self->pg
    )->load_rfq_p($rfqs_pkey);
}

sub save_rfq_p{
    my ($self, $data) = @_;

    return Order::Model::Rfqs->new(
        pg => $self->pg
    )->save_rfq_p($data);
}

sub send_rfq_message {
    my ($self, $data, $minion) = @_;

    my $result = try {
        my $rfq_no = Order::Model::Rfqs->new(
            pg => $self->pg
        )->save_rfq($data);

        say "rfq_no " . $rfq_no;
        my $message->{rfq} = Order::Model::Rfqs->new(
            pg => $self->pg
        )->load_from_rfqno($rfq_no)->hash;

        $message->{type} = 'rfq_sent';
        $message->{customer} = $data->{company};
        $message->{customer_user} = $data->{userid};
        $message->{supplier} = $data->{supplier};

        $minion->enqueue('send_rfq' => [ $message ] => { priority => 0 });

        return $rfq_no;
    } catch {
        say $_;
        $self->capture_message(
            '', 'Order::Helper::Rfqs::send_rfq_message', 'send_rfq_message', (caller(0))[3], $_
        );
        return $_;
    };

    return $result;

}

sub set_setdefault_data{
    my ($self, $data) = @_;

    return Order::Model::Rfqs->new(
        pg => $self->pg
    )->set_setdefault_data($data);
}

sub _send_rfq{
    my($job, $data) = @_;

    my $result = send_rfq($job->app->pg, $job->pp->config, $data);

    $job->finish({ status => $result});
}

sub send_rfq{
    my ($pg, $config, $data) = @_;

    my $result = try {
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();

        $year = "20$year";
        $data->{sentat} = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
        $data->{messagetype} = 'rfq_sent';

        Order::Helper::Rfqs::Messenger->new(
            pg     => $pg,
            config => $config
        )->send_message($data);

        Order::Model::Rfqs->new(
            pg => $pg
        )->set_sent_at($data);
        return 'Success';
    } catch {
        Daje::Utils::Sentinelsender->new()->capture_message(
            '', 'Order::Helper::Rfqs::send_rfq_message', 'send_rfq', (caller(0))[3], $_
        );
        return $_;
    };
    return $result;
}

sub send_rfq_test {
    my ($self, $pg, $config, $data) = @_;

    my $result = send_rfq($pg, $config, $data);

    return $result;
}

sub set_sent_at{
    my ($self, $data) = @_;

    return Order::Model::Rfqs->new(
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