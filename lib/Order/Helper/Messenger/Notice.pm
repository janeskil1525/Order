package Order::Helper::Messenger::Notice;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::UserAgent;

has 'message' => '';
has 'title' => '';
has 'subtitle' => '';
has 'highSubtitle' => '';
has 'subContent' => '';
has 'error' => 'false';
has 'company' => '';
has 'userid' => '';
has 'type' => 'notice';


sub get_payload{
    my $self= shift;

    my $payload->{title} = $self->title();
    $payload->{subtitle} = $self->subtitle();
    $payload->{highSubtitle} = $self->highSubtitle();
    $payload->{subContent} = $self->subContent();
    $payload->{company} = $self->company();
    $payload->{userid} = $self->userid();
    $payload->{type} = $self->type();
    $payload->{message} = $self->message();
    $payload->{error} = $self->error();



    return $payload;
}


1;