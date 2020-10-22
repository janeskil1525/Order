package Order::Helper::Orion::Communicator::BaseXML;
use Mojo::Base 'Daje::Utils::Sentinelsender';

use Data::Dumper;
#use HTTP::Headers;
use XML::Hash::XS;
use LWP::UserAgent;
use HTTP::Request;

sub post_xml {

    my $xmlstr = $conv->hash2xml(
        {
            xmlns => 'http://opencarpartinterface.org/2011/09',
            reservations => [
                {
                    Reservation => {
                        carbreaker      => [ 'F' ],
                        partid          => [ '22569490' ],
                        reservationtype => [ 2 ],
                        id              => [ 0 ],
                        extreference    => [ '12345' ],
                        extsource       => [ 'LagaPro' ],
                        usersign        => [ 'Jan' ],
                    }
                }
            ]
        },
        utf8 => 1,
        root => 'SaveReservations',
        use_attr  => 1,
        canonical => 1,
    );

    say $xmlstr;

    my $ua = LWP::UserAgent->new();
    my $request = HTTP::Request->new(POST => 'http://testws.bosab.se/RestIntegrationService.svc/pox/SaveReservations');
    $request->content_type("text/xml; charset=utf-8");
    $request->content($xmlstr);
    $request->header(Authorization => 'Fenix Norr:q81k', 'Content-Type' => "text/xml; charset=utf-8");

    my $response = $ua->request($request);

    if($response->is_success) {
        print $response->decoded_content;

        my $xml_result = $conv->xml2hash($response->decoded_content);
        say Dumper($xml_result);
    }
    else {
        print $response->error_as_HTML;
    }

}

1;