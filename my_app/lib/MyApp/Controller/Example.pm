package MyApp::Controller::Example;
use Mojo::Base 'Mojolicious::Controller', -signatures;

sub barcode ($self) {
  $self->render(text => $self->param('input'));
}

# This action will render a template
sub welcome ($self) {

  # Render template "example/welcome.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

1;
