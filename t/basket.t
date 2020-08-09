use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::Pg;
use Mojo::JSON qw{encode_json};
use Data::Dumper;


helper pg => sub { state $pg = Mojo::Pg->new->dsn("dbi:Pg:dbname=WebShop;host=81.216.60.23;port=15432;user=postgres;password=PV58nova64")};
plugin 'Minion' => {Pg => app->pg};
plugin 'Shoppingcart' => {pg => app->pg, minion => app->minion};;
plugin 'Settings' => {lan => 'swe',
							   pg => app->pg};
plugin 'Translations' => {pg => app->pg};

get '/mock/' => sub {
    my $c = shift;

    my $token = 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F';
    my $tx =  $c->app->pg->db->begin;
    eval{
        my $users_pkey = $c->app->pg->db->insert('users',
            {userid => 'kalle@olle.com', username => 'kalle', passwd => 'kalle', menu_group => 1},
            {returning => 'users_pkey'})->hash->{users_pkey};
        my $companies_pkey = $c->app->pg->db->insert('companies',
            {company => 'testbolaget', menu_group => 1},
            {returning => 'companies_pkey'})->hash->{companies_pkey};
        $c->app->pg->db->delete('users_token',
            {token => $token});
        $c->app->pg->db->insert('users_token',
            {token => $token, users_fkey => $users_pkey});
        $c->app->pg->db->insert('users_companies',
            {companies_fkey => $companies_pkey, users_fkey => $users_pkey});
        my $addresses_pkey = $c->app->pg->db->insert('addresses',
            {name => 'testbolaget', address1 => 'Stora vägen', city => 'Motala', zipcode => '597 91'},
            {returning => 'addresses_pkey'})->hash->{addresses_pkey};
        $c->app->pg->db->insert('addresses_company',
            {companies_fkey => $companies_pkey, addresses_fkey => $addresses_pkey});
        $tx->commit;
    };

    say $@ if $@;

    $c->render(json => {success => 1});
};

post '/basket/upsertitem/' => sub {
  my $c = shift;
  
  my $condition = $c->req->content->asset->slurp;
  my $result = $c->shoppingcart->upsertItem($condition);

  $c->render(json => $result->{reault});
};

get '/basket/load/:basketid/' => sub {
    my $c = shift;

  my $basketid = $c->param('basketid');
  my $token = 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F';
  
  my $response->{basket} = $c->shoppingcart->loadBasket($basketid, $token);
	
	my $test_json  = encode_json $response;
	
  $c->render(json => $response);
};

get '/basket/loadfull/:basketid/' => sub {
  my $c = shift;
  
  my $basketid = $c->param('basketid');
  my $token = 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F';
  
  my $response->{basket} = $c->shoppingcart->loadBasketFull($basketid, $token);
	
	my $test_json  = encode_json $response;
	
  $c->render(json => $response);
};

get '/basket/open/' => sub {
  my $c = shift;
  
  
  my $token = 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F';
  
  my $response = $c->shoppingcart->openBasket($token);
	
	my $test_json  = encode_json $response;
	
  $c->render(json => $response);
};


del '/basket/delete/:basketid/' => sub {
  my $c = shift;
  my $basketid = $c->param('basketid');
  my $result = $c->shoppingcart->dropBasket($basketid);
  $c->render(json => $result);
};


post '/basket/checkout' => sub {
  my $c = shift;
  my $condition = $c->req->content->asset->slurp;
  my $result = $c->shoppingcart->checkOut($condition);
	
  $c->render(json => $result);
};

post '/basket/savebasket' => sub {
  my $c = shift;
  my $condition = $c->req->content->asset->slurp;
  my $result = $c->shoppingcart->saveBasket($condition);
	
  $c->render(json => $result);
};

get '/teardown/' => sub {
    my $c = shift;

    my $token = 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F';
    my $tx =  $c->app->pg->db->begin;
    eval{

        my $users_pkey = $c->app->pg->db->select('users_token',
            ['users_fkey'],
            {token => $token})->hash->{users_fkey};
        my $companies_pkey = $c->app->pg->db->select('users_companies',
            ['companies_fkey'], {users_fkey => $users_pkey})->hash->{companies_fkey};
        my $addresses_pkey = $c->app->pg->db->select('addresses_company',
            ['addresses_fkey'], {companies_fkey => $companies_pkey})->hash->{addresses_fkey};

        $c->app->pg->db->delete('users_token',
            {users_fkey => $users_pkey});
        $c->app->pg->db->delete('users_companies',
            {users_fkey => $users_pkey});
        $c->app->pg->db->delete('addresses_company',
            {companies_fkey => $companies_pkey});
        $c->app->pg->db->delete('companies',
            {companies_pkey => $companies_pkey});
        $c->app->pg->db->delete('addresses',
            {addresses_pkey => $addresses_pkey});
        $c->app->pg->db->delete('users',
            {users_pkey => $users_pkey});

        $tx->commit;
    };

    say $@ if $@;

    $c->render(json => {success => 1});
};

my $t = Test::Mojo->new;

$t->get_ok('/mock')->status_is(200)->json_has('/success');


$t->post_ok('/basket/upsertitem/' => {Accept => '*/*'} => json => {
    token           => 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F',
    basketid        => '123456543321234',
    stockitem       => '123456',
    quantity        => '1',
    price           => "100.00",
    itemno          => '10',
    supplier_fkey   => 5,
    stockitems_pkey => 11565235,
    description     => 'Test',
})->status_is(200)->json_has('result');;
 $t->post_ok('/basket/upsertitem/' => {Accept => '*/*'} => json => {
 	token => 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F',
 	basketid => '123456543321234',
 	stockitem => '1234578',
 	quantity => '1',
 	price => "1000.00",
 	itemno => '20',
 	supplier_fkey => 4,
     stockitems_pkey => 11565235,
    description     => 'Test',
 	})->status_is(200)->json_has('result');;
 $t->post_ok('/basket/upsertitem/' => {Accept => '*/*'} => json => {
 	token => 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F',
 	basketid => '123456543321234',
 	stockitem => '1234579',
 	quantity => '1',
 	price => "1000.00",
 	itemno => '30',
 	supplier_fkey => 3,
     stockitems_pkey => 11565235,
     description     => 'Test',
 })->status_is(200)->json_has('result');;
 #$t->post_ok('/basket/upsertitem/' => {Accept => '*/*'} => json => {basket => '123456543321235', stockitem => '123457', quantity => '1', price => "100.00", itemno => '20'})->status_is(200)->content_is('OK');;

 $t->get_ok('/basket/open/')->status_is(200)->json_has('/openitems');
 $t->get_ok('/basket/load/123456543321234')->status_is(200)->json_has('/basket');

 $t->post_ok('/basket/savebasket/' => {Accept => '*/*'} => json => {
   basketid => '123456543321234',
   token => 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F',
   payment => 'Invoice',
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

 $t->get_ok('/basket/loadfull/123456543321234')->status_is(200)->json_has('/basket');

 $t->post_ok('/basket/checkout/' => {Accept => '*/*'} => json => {
   basketid => '123456543321234',
   token => 'D19EFAD2-F19A-11E8-BC93-B2B020B37D0F',
   payment => 'Invoice',
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


 $t->delete_ok('/basket/delete/123456543321234')->status_is(200)->json_has('/deleted');
 $t->get_ok('/basket/open/')->status_is(200)->json_has('/openitems');

$t->get_ok('/teardown')->status_is(200)->json_has('/success');
done_testing();
