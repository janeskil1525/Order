package WebShop::Helper::Mail::User::RfqSent;
use Mojo::Base 'WebShop::Helper::Mail::Base::Common';

use WebShop::Model::Mailer;
use Try::Tiny;
use HTML::Entities;


sub createAndSendMail{
    my ($self, $data) = @_;

    my $user = $self->_get_user($data->{users_fkey});

    my $templatedata;
    $templatedata->{companies_pkey} = $data->{supplier_fkey};
    $templatedata->{users_pkey} = $data->{users_fkey};
    $templatedata->{mailtemplate} = 'rfqsent';
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
        'Ny offert förfrågan i LagaPro',
        $attachement
    );

    return $result;
}



1;
