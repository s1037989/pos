package Item;
use Mojo::Base -base, -signatures;

use Math::Currency qw(Money);

has [qw/barcode name _cost/];
has inventory => 1;

sub cost ($self, $cost=undef) {
  defined $cost ? $self->_cost($cost) : Money(defined $self->_cost ? $self->_cost : 0);
}

sub new {
  my $self = shift->SUPER::new;
  return undef unless @_ >= 3;
  $self->barcode(shift)->name(shift)->cost(shift);
  $self->inventory(shift) if $_[0];
  return $self;
}

1;