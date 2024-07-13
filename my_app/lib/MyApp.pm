package MyApp;
use Mojo::Base 'Mojolicious', -signatures;

# This method will run once at server start
sub startup ($self) {

  # Load configuration from config file
  my $config = $self->plugin('NotYAMLConfig');

  # Configure the application
  $self->secrets($config->{secrets});

  my $store_status = 'closed';
  $self->helper(
    store_status => sub ($c, $status=undef) {
      if ($status) {
        $store_status = $status;
      }
      return $store_status;
    }
  );

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('Example#welcome');
  $r->post('/get_barcode')->to('Example#get_barcode');
  $r->post('/open_store')->to('Example#open_store');
  $r->post('/close_store')->to('Example#close_store');
  $r->post('/store_status')->to('Example#store_status');
}

1;
