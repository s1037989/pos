package Cart;
use Mojo::Base -base, -signatures;

use Math::Currency qw(Money);
use Mojo::Collection;
use Scalar::Util qw(looks_like_number);

use constant TAX_RATE => 9.17 / 100;

has finish => 0;
has items => sub { Mojo::Collection->new };
has store => sub { die };

sub add_item($self, $item) {
  return unless $item && $item->barcode;
  return push @{$self->items}, $item if $self->store->carts->map(sub { $_->items->grep(sub { $_->barcode eq $item->barcode })->size })->reduce(sub { $a + $b }, 0) < $self->store->inventory->first(sub{$_->barcode eq $item->barcode})->inventory; 
  return undef;
}

sub end_sale ($self) {
  warn sprintf "Subtotal for %d items: %s", $self->size, $self->subtotal;
  warn sprintf "%.4f%% Tax: %s", TAX_RATE * 100, $self->tax;
  warn sprintf "Balance Due: %s", $self->total;
  warn "Enter amount paid: ";
  my $paid = 100; #chomp(my $paid = <STDIN>);
  $paid = substr($paid, 0, 5);
  $paid =~ s/[^\d\.]//g;
  warn "End sale aborted" and return unless looks_like_number($paid);
  $paid = Money($paid);
  warn sprintf "Change due: %s", $paid - $self->total;
  Change->new($paid - $self->total);
  warn "\n";
  $self->finish(1);
}

sub size { shift->items->size };

sub subtotal ($self) { $self->items->reduce(sub { $a + $b->cost }, Money(0)) }

sub tax ($self) { $self->subtotal * TAX_RATE }

sub total ($self) { $self->subtotal + $self->tax };

sub void_item ($self) {
  warn "Scan item to void from cart: ";
  my $barcode = "%123"; #chomp(my $barcode = <STDIN>);
  $barcode = substr($barcode, 0, 20);
  $barcode = chr hex $barcode =~ s/^%%//r if $barcode =~ /^%%/;
  warn "How many to remove? (enter 0 for all, default is 1) ";
  my $qty; #chomp(my $qty = <STDIN>);
  $qty = substr($qty, 0, 5);
  $qty =~ s/\D//g;
  $qty ||= 1;
  $self->void_item($barcode, $qty);
  warn "Voided $barcode";
  my $delete = 0;
  $self->inventory->reduce(sub {
    push @$a, $b unless $delete == 1 || $b->barcode eq $barcode;
    $delete++ if $b->barcode eq $barcode;
  }, Mojo::Collection->new);
}

1;