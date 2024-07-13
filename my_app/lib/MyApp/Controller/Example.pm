package MyApp::Controller::Example;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub close_store ($self) {
  $self->app->store_status('closed');
  $self->render(json => {
    status => 'success',
    message => 'Close Store',
  });
}

sub get_barcode ($self) {
  $self->render(json => {
    barcode => $self->req->json('/barcode'),
    name => 'Test',
  });
}

sub open_store ($self) {
  $self->app->store_status('open');
  $self->render(json => {
    status => 'success',
    message => 'Open Store',
  });
}

sub store_status ($self) {
  $self->render(json => {
    status => $self->app->store_status,
  });
}

# This action will render a template
sub welcome ($self) {

  # Render template "example/welcome.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

1;
