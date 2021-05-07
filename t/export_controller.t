use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('Order');
my $post_data->{system} = 'orion';
$t->post_ok('/api/v1/order/export/' => {
        'X-Token-Check' => 'c6629f75-e46d-4829-adea-23451410b495'
    } => json => $post_data
)->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();




