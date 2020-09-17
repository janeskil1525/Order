package Matorit::Orion::Communicator::Base;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Mojo::UserAgent;

has 'endpoint_address';
has 'endpoint_path';
has 'username';
has 'password';
has 'ua';

sub get_data{
    my ($self, $data) = @_;

    my $endpoint = $self->endpoint_address() . "RestIntegrationService.svc/pox/" . $self->endpoint_path();

    $endpoint .= $data if $data;
    my $headers = $self->get_headers();
    my $ua = Mojo::UserAgent->new();
    $ua->inactivity_timeout(90);
    $ua->max_connections(10);

    return $ua->get($endpoint => $headers);;
}

sub get_data_p{
    my ($self, $data) = @_;

    my $endpoint = $self->endpoint_address() . "RestIntegrationService.svc/pox/" . $self->endpoint_path();

    $endpoint .= $data if $data;
    my $headers = $self->get_headers();
    my $ua = Mojo::UserAgent->new();
    $ua->inactivity_timeout(90);
    $ua->max_connections(10);

    return $ua->get_p($endpoint => $headers);;
}

sub post_data{
    my ($self, $data) = @_;

    my $endpoint = $self->endpoint_address() . "RestIntegrationService.svc/pox/" . $self->endpoint_path();

    my $headers = $self->get_headers();
    my $ua = Mojo::UserAgent->new();
    $ua->inactivity_timeout(60);

    return $ua->post($endpoint => $headers => json => $data);;
}

sub post_data_p{
    my ($self, $data) = @_;

    my $endpoint = $self->endpoint_address() . "RestIntegrationService.svc/pox/" . $self->endpoint_path();

    my $headers = $self->get_headers();
    my $ua = Mojo::UserAgent->new();
    $ua->inactivity_timeout(60);

    return $ua->post_p($endpoint => $headers => json => $data);
}

sub post_file{
    my ($self, $data, $file) = @_;

    my $endpoint = $self->endpoint_address() .
        "RestIntegrationService.svc/pox/" .
        $self->endpoint_path() . $data;

    my $headers = $self->get_headers();
    $headers->{'Content-type'} = 'application/octet-stream';

    my $ua = Mojo::UserAgent->new();
    $ua->inactivity_timeout(60);

    return $ua->post($endpoint => $headers => $file);;
}

sub post_file_p{
    my ($self, $id, $data) = @_;

    my $endpoint = $self->endpoint_address() .
        "RestIntegrationService.svc/pox/" .
        $self->endpoint_path() .
        '?id=' .
        $id;

    my $headers = $self->get_headers();
    $headers->{'Content-type'} = 'application/octet-stream';
    # $headers->{'Content'} = $data->{content};

    my $ua = Mojo::UserAgent->new();
    $ua->inactivity_timeout(60);

    return $ua->post_p($endpoint => $headers => $data);;
}

sub post_multipart {
    my ($self, $data, $file) = @_;

    my $endpoint = $self->endpoint_address() .
        "RestIntegrationService.svc/pox/" .
        $self->endpoint_path();

    my $headers = $self->get_headers('multipart/form-data');
    #$headers->{'Content-type'} = 'application/octet-stream';

    my $multipart->{multipart} = [
        {
            'Content-Type' => 'application/json; charset=UTF-8',
            content =>  $data,
        },
        {
            'Content-Type' => 'application/octet-stream',
            content => $file->slurp,
        }
    ];

    my $ua = Mojo::UserAgent->new();
    $ua->inactivity_timeout(60);

    my $res = $ua->post($endpoint => $headers => $multipart)->result;

    return $res;
}

sub get_headers{
    my ($self, $content_type) = @_;

    $content_type = 'application/json' unless $content_type;

    my $headers;
    my $user = $self->get_authorization();

    $headers->{'Content-type'} = $content_type;
    $headers->{'Authorization'} = $user;
    return $headers;
}

sub get_authorization{
    my $self = shift;

    my $authorization = 'Fenix ' . $self->username() . ":" . $self->password();
    return $authorization;
}

1;