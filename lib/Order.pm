package Order;
use Mojo::Base 'Mojolicious';

use Order::Model::Menu;
use Order::Model::Users;
use Order::Model::Companies;
use Mojo::Pg;


# This method will run once at server start
sub startup {
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});
  $self->helper(pg => sub {state $pg = Mojo::Pg->new->dsn(shift->config('pg'))});
  $self->log->path($self->config('log'));

  $self->helper(menu => sub { state $menu = Order::Model::Menu->new(pg => shift->pg)});
  $self->helper(users => sub { state $users = Order::Model::Users->new(pg => shift->pg)});
  $self->helper(companies => sub { state $users = Order::Model::Companies->new(pg => shift->pg)});

  say $self->pg->db->query('select version() as version')->hash->{version};

  my $path = $self->home->child('migrations', 'order.sql');
  $self->pg->migrations->name('order')->from_file($path)->migrate(1);
  $self->plugin('Minion'  => { Pg => $self->pg });
  $self->plugin('Subscription');

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

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('login#showlogin');
  $r->post('/login')->to('login#login');
  $auth_route->get('/menu/show')->to('menu#showmenu');
  $auth_route->get('/companies/list/')->to('companies#list');
  $auth_route->get('/users/list/')->to('users#list');

}

1;
