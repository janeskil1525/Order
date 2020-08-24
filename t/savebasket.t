use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Pg;
use Mojo::JSON qw{encode_json};
# use Order::Helper::Shoppingcart;
use Data::Dumper;


my $t = Test::Mojo->new('Order');

$t->post_ok('/api/v1/basket/checkout/' => {Accept => '*/*'} => json => {
   basketid => 'f39222f9-c3ed-56ac-e6f5-cf73b3a6ddc2',
      token => 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F',
    userid => 'jan@daje.work',
    company => 'F',
   payment => 'Invoice',
   approved => 0,
    invoiceaddress => {
     name => 'Knep & Klåp AB',
     address1 => 'Lilla vägen 10',
     zipcode => '597 91',
     city => 'Motala',
     country => 'Sweden'
    },
    deliveryaddress => {
    name => 'Knep & Klåp AB',
       address1 => 'Stora vägen 10',
       address2 => 'Port 4',
       zipcode => '597 91',
       city => 'Motala',
       country => 'Sweden'
    }
  })->status_is(200)->json_has('/basket_pkey');;
#
done_testing();

