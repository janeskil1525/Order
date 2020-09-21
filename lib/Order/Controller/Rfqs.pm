package Order::Controller::Rfqs;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON qw{decode_json};
use Data::Dumper;

sub list_all_rfqs_from_status_api{
    my $self = shift;

    $self->render_later;
    my $response;
    my $token = $self->req->headers->header('X-Token-Check');
    my $fields_list = $self->settings->get_settings_list('Rfqs_grid_fields', $token);
    my $rfqstatus = $self->param('rfqstatus');
    say $rfqstatus;
    $self->user->get_company_fkey_from_token_p($token)->then(sub{
        my $collection = shift;

        my $company_pkey = $collection->hash->{companies_fkey};
        $self->rfqs->list_all_rfqs_from_status_p($company_pkey)->then(sub{
            my $result = shift;

            $response->{data} = $result->hashes->to_array;;
            $response->{responses} = $result->rows;
            $response->{headers} = $self->translations->grid_header('Rfqs_grid_fields',$fields_list,'swe');

            $self->render(json => $response);
        })->catch(sub{
            my $err = shift;

            $response->{header_data} = '';
            $response->{error} = $err;
            say $err;
            $self->render(json => $response);
        })->wait;

    })->catch(sub{
        my $err = shift;

        $response->{header_data} = '';
        $response->{error} = $err;
        say $err;
        $self->render(json => $response);
    })->wait;
}

sub load_rfq_api{
    my $self = shift;

    $self->render_later;
    my $validator = $self->validation;
    if($validator->required('rfqs_pkey')){
        my $rfqs_pkey = $self->param('rfqs_pkey');
        if($rfqs_pkey eq 'new') {$rfqs_pkey = 0};

        $self->rfqs->load_rfq_p($rfqs_pkey)->then(sub{
            my $result = shift;

            my $field_list;
            my $rfq = $result->hash;
            $result->finish;
            ($rfq, $field_list) = $self->rfqs->set_setdefault_data($rfq);

            my $detail = Daje::Utils::Translations->new(
                pg => $self->pg
            )->details_headers(
                'rfqs', $field_list, $rfq, 'swe');

            $rfq->{header_data} = $detail;

            $self->render(json => $rfq);
        })->catch(sub {
            my $err = shift;

            $self->render(json => {error => $err});
        })->wait;
    }
}

sub save_rfq_api{
    my $self = shift;

    my $token = $self->req->headers->header('X-Token-Check');

    $self->render_later;
    my $body = $self->req->body;
    my $data = decode_json($body);
    delete $data->{header_data} if exists $data->{header_data};

    unless (exists $data->{companies_fkey} and $data->{companies_fkey} > 0){
        $data->{companies_fkey} = $self->companies->load_loggedincompany($token)->{companies_pkey};
    }

    unless (exists $data->{users_fkey} and $data->{users_fkey} > 0){
        $data->{users_fkey} = $self->user->load_token_user(
            $token
        )->hash->{users_pkey};
    }
    $data->{sent} = 'false' unless $data->{sent};
    $data->{rfqstatus} = 'NEW' unless $data->{rfqstatus};

    $self->rfqs->save_rfq_p($data)->then(sub{
        my $result = shift;

        my $rfq_no = $result->hash->{rfq_no};
        $result->finish();
        $self->render(json => {rfq_no => $rfq_no, result => 'Success'});
    })->catch(sub{
        my $err = shift;

        $self->render(json => {result => {error => $err} });
    })->wait;
}

sub send_rfq_api{
    my $self = shift;

    my $token = $self->req->headers->header('X-Token-Check');

    $self->render_later;

    my $body = $self->req->body;
    my $data = decode_json($body);
    delete $data->{header_data} if exists $data->{header_data};

    unless (exists $data->{companies_fkey} and $data->{companies_fkey} > 0){
        $data->{companies_fkey} = $self->companies->load_loggedincompany(
            $token
        )->{companies_pkey};
    }

    unless (exists $data->{users_fkey} and $data->{users_fkey} > 0){
        $data->{users_fkey} = $self->user->load_token_user(
            $token
        )->hash->{users_pkey};
    }

    $data->{rfqstatus} = 'NEW' unless $data->{rfqstatus};
    $data->{sent} = 'true';
    $self->rfqs->send_rfq_p($data)->then(sub{
        my $rfq_no = shift;

        $self->render(json => {rfq_no => $rfq_no, result => 'Success'});
    })->catch(sub{
        my $err = shift;

        $self->render(json => {error => $err});
    })->wait;
}
1;
