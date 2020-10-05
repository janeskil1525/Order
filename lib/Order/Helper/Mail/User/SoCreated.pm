package WebShop::Helper::Mail::User::SoCreated;
use Mojo::Base 'WebShop::Helper::Mail::Base::Common';

use WebShop::Model::Mailer;
use Try::Tiny;
use HTML::Entities;



sub createAndSendMail{
    my ($self, $data) = @_;

    my $templatedata;

    my $order_head = $self->_get_order_head($data->{salesorder_head_pkey});
    my $user = $self->_get_user($order_head->{users_fkey});

    $templatedata->{companies_pkey} = $order_head->{companies_fkey};
    $templatedata->{users_pkey} = $order_head->{users_fkey};
    $templatedata->{mailtemplate} = 'socreated';
    $templatedata->{lan} = 'swe';

    my $template = $self->_get_template($templatedata);

    my $link = qq{<a href="} . $self->{server_adress} . qq{">LagaPro};
    $template->{body_value} = encode_entities($template->{body_value});
    my $body = $template->{body_value} =~ s/ADDRESS_TO_BEREPLACED/$link/r . qq{</a>};
    my $header = $template->{header_value} =~ s/LAGAPROLINKANDTEXT/$body/r;

    my $footer = $template->{footer_value};

    my $attachement;
    $attachement = $self->_get_attachement($attachement, 'text/html', $header . $footer);

    my $result = $self->_send_mail(
        $user->{userid},
        'Ny kundorder i LagaPro',
        $attachement
    );

    return $result;
}

1;
