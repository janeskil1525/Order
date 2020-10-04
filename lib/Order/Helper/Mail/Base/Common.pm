package WebShop::Helper::Mail::Base::Common;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use WebShop::Model::User;
use WebShop::Model::Mailer;
use Daje::Order::Order;

has 'pg';
has 'image_storage_root';
has 'server_adress';
has 'mailserver_address';
has 'mailserver_key';

sub _get_template{
    my ($self, $template) = @_;

    return  WebShop::Model::Mailer->new(
        pg => $self->pg
    )->load_template($template);
}

sub _get_user{
    my ($self, $users_pkey) = @_;

    return  WebShop::Model::User->new(
        pg => $self->pg
    )->load_user($users_pkey)->hash;
}

sub _get_order_head{
    my ($self, $order_head_pkey) = @_;

    return  WebShop::Order::Order->new(
        pg => $self->pg
    )->load_order_head($order_head_pkey)->hash;
}

sub _get_attachement{
    my ($self, $attachement, $type, $data) = @_;

    $type = 'text/html' unless $type;
    
    my $att;
    $att->{type} = $type;
    $att->{data} = $data;
    push @{$attachement}, $att;

    return $attachement;
}
1;
