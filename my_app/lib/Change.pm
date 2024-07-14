package Change;
use Mojo::Base -base, -signatures;

sub new {
  my $self = shift->SUPER::new;
  my $amount = shift->as_float;
  my @denominations = (
    100.00, # $100 bills
    50.00,  # $50 bills
    20.00,  # $20 bills
    10.00,  # $10 bills
    5.00,   # $5 bills
    1.00,   # $1 bills
    0.25,   # Quarters
    0.10,   # Dimes
    0.05,   # Nickels
    0.01    # Pennies
  );
  my @denom_names = (
    '$100 bills', '$50 bills', '$20 bills', '$10 bills', '$5 bills', '$1 bills',
    'Quarters', 'Dimes', 'Nickels', 'Pennies'
  );
  my @quantities;

  foreach my $denom (@denominations) {
    my $count = int($amount / $denom);
    push @quantities, $count;
    $amount -= $count * $denom;
  }

  for my $i (0..$#quantities) {
    warn "  $denom_names[$i]: $quantities[$i]\n" if $quantities[$i] > 0;
  }
}

1;