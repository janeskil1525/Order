package Order::Helper::Order::Notice;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::UserAgent;

has 'message' => '';
has 'title' => '';
has 'subtitle' => '';
has 'highSubtitle' => '';
has 'subContent' => '';
has 'error' => 'false';
has 'company' => 0;
has 'userid' => 0;
has 'type' => 'notice';

has config;

sub get_payload{
    my $self= shift;

    my $payload->{title} = $self->title();
    $payload->{subtitle} = $self->subtitle();
    $payload->{highSubtitle} = $self->highSubtitle();
    $payload->{subContent} = $self->subContent();
    $payload->{companies_fkey} = $self->companies_fkey();
    $payload->{users_fkey} = $self->users_fkey();
    $payload->{type} = $self->type();
    $payload->{message} = $self->message();
    $payload->{error} = $self->error();

    return $payload;
}

sub send_notice {
    my ($self, $payload) = @_;

    $ua->post_p(
        $self->config->{messenger}->{endpoint} => {
            Accept => '*/*'
        } => json => $payload
    )->then(sub{
        my $tx = shift;

    })->catch(sub{
        my $err = shift;

        $self->capture_message('','Order::Helper::Order::Notice::send_notice', (ref $self), (caller(0))[3], $err);
    });
}
1;