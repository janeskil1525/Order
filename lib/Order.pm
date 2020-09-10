package Order;
use Mojo::Base 'Mojolicious';

use Order::Model::Menu;
use Order::Model::Users;
use Order::Helper::Shoppingcart;
use Order::Helper::Shoppingcart::Converter;

use Mojo::Pg;
use Mojo::JSON qw{encode_json from_json};
use Mojo::File;
use File::Share;

$ENV{ORDER_HOME} = '/home/jan/Project/Order/'
    unless $ENV{ORDER_HOME};

has dist_dir => sub {
  return Mojo::File->new(
      File::Share::dist_dir('Order')
  );
};

has home => sub {
  Mojo::Home->new($ENV{ORDER_HOME});
};

# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});
  $self->helper(pg => sub {state $pg = Mojo::Pg->new->dsn(shift->config('pg'))});
  $self->log->path($self->home() . $self->config('log'));
  $self->helper(menu => sub { state $menu = Order::Model::Menu->new(pg => shift->pg)});
  $self->helper(users => sub { state $users = Order::Model::Users->new(pg => shift->pg)});
  $self->helper(order => sub { state $order = Order::Helper::Order->new(pg => shift->pg)});
  $self->helper(shoppingcart => sub { state $shoppingcart = Order::Helper::Shoppingcart->new(pg => shift->pg)});
  $self->shoppingcart->config($self->config);
  $self->helper(converter => sub { state $converter = Order::Helper::Shoppingcart::Converter->new(pg => shift->pg)});


  say $self->pg->db->query('select version() as version')->hash->{version};

  $self->renderer->paths([
      $self->dist_dir->child('templates'),
  ]);
  $self->static->paths([
      $self->dist_dir->child('public'),
  ]);

  $self->pg->migrations->name('order')->from_file(
      $self->dist_dir->child('migrations/order.sql')
  )->migrate(14);

  my $schema = from_json(
      Mojo::File->new($self->dist_dir->child('schema/order.json'))->slurp
  );

  $self->plugin('Minion'  => { Pg => $self->pg });
  $self->plugin('Subscription');

  $self->converter->init($self->minion);

  # Router
  my $auth_route = $self->routes->under( '/app', sub {
    my ( $c ) = @_;

    return 1 if ($c->session('auth') // '') eq '1';
    $c->redirect_to('/');
    return undef;
  } );

  my $auth_minion = $self->routes->under( '/minion', sub {
    my ( $c ) = @_;

    return 1 if ($c->session('auth') // '') eq '1';
    $c->redirect_to('/');
    return undef;
  } );


  my $auth_api = $self->routes->under( '/api', sub {
    my ( $c ) = @_;

    return 1;
    #return 1 if $c->user->authenticate($c->req->headers->header('X-Token-Check'));
    # Not authenticated
    $c->render(json => '{"error":"unknown error"}');
    return undef;
    return undef;
  } );

  $self->plugin('Human', {

      # Set money parameters if you need
      money_delim => ",",
      money_digit => " ",

      # Local format for date and time strings
      datetime    => '%Y-%m-%d %H:%M:%S',
      time        => '%H:%M:%S',
      date        => '%Y-%m-%d',

      phone_country   => 1,
  });

  $self->plugin('Minion::Admin' => { route => $auth_minion});

  my $auth_yancy = $self->routes->under( '/yancy', sub {
    my ( $c ) = @_;

    return 1 if ($c->session('auth') // '') eq '1';
    $c->redirect_to('/');
    return undef;
  } );

  $self->plugin(
      'Yancy' => {
          route       => $auth_yancy,
          backend     => {Pg => $self->pg},
          schema      => $schema,
          read_schema => 0,
          'editor.return_to'   => '/app/menu/show/',
          'editor.require_user' => undef,
      }
  );

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('login#showlogin');
  $r->post('/login')->to('login#login');
  $auth_route->get('/menu/show')->to('menu#showmenu');
  $auth_route->get('/companies/list/')->to('companies#list');
  $auth_route->get('/users/list/')->to('users#list');

  $auth_api->get('/v1/orders/purchase/')->to('orders#list_purchaseorders');
  $auth_api->get('/v1/orders/sales/')->to('orders#list_salesorders');
  $auth_api->get('/v1/orders/item/load/')->to('orders#load_item_api');
  $auth_api->get('/v1/orders/load/purchase/:orders_pkey')->to('orders#load_purchase_order_api');
  $auth_api->get('/v1/orders/load/sales/:orders_pkey')->to('orders#load_sales_order_api');

  $auth_api->post('/v1/basket/upsertitem/')->to("basket#upsertitem");
  $auth_api->get('/v1/vehicle/getforregplate:regplate')->to("basket#getforregplate");
  $auth_api->get('/v1/basket/load/:basketid')->to('basket#load_basket');

  $auth_api->post('/v1/basket/open/')->to('basket#open_basket');

  $auth_api->get('/v1/basket/items/:itemtype')->to('basket#list_basket_items_itemtype_api');
  $auth_api->get('/v1/basket/item/load/:basket_item_pkey')->to('basket#basket_items_load_api');
  $auth_api->post('/v1/basket/checkout/')->to('basket#checkout');

  $auth_api->get('/v1/rfqs/list/:rfqstatus')->to('rfqs#list_all_rfqs_from_status_api');
  $auth_api->get('/v1/rfqs/load/:rfqs_pkey')->to('rfqs#load_rfq_api');
  $auth_api->post('/v1/rfqs/save/')->to('rfqs#save_rfq_api');
  $auth_api->post('/v1/rfqs/send/')->to('rfqs#send_rfq_api');

}

1;
