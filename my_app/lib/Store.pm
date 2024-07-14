package Store;
use Mojo::Base -base, -signatures;

use Math::Currency qw(Money);
use Mojo::Collection;
use Scalar::Util qw(looks_like_number);
use Storable ();
# use Term::ReadKey;

has carts => undef;
has file => sub { die };
has inventory => undef;
has name => 'The Store';

sub add_item ($self) {
  warn "Adding new item, scan new item barcode: ";
  my $barcode = $self->get_barcode(1) or return;
  my $item = $self->inventory->first(sub{$_->barcode eq $barcode});
  warn sprintf "Already added item %s (%s)", $item->name, $item->barcode and return $self->edit_item($item) if $item;
  warn "Add item name for new barcode $barcode: ";
  my $name = 'Test'; #chomp(my $name = <STDIN>);
  warn "Add item aborted" and return unless $name;
  warn "Add item $name cost: ";
  my $cost; #chomp(my $cost = <STDIN>);
  $cost = substr($cost, 0, 5);
  $cost =~ s/[^\d\.]//g;
  $cost ||= sprintf '%.2f', rand(10);
  warn "Add item aborted" and return unless looks_like_number($cost);
  warn "Add item $name quantity: ";
  my $qty; #chomp(my $qty = <STDIN>);
  $qty = substr($qty, 0, 5);
  $qty =~ s/\D//g;
  $qty ||= 1;
  warn "Add item aborted" and return unless looks_like_number($qty);
  $item = Item->new($barcode, $name, $cost, $qty);
  push @{$self->inventory}, $item;
  warn sprintf "Added %s (%s) for %s to inventory!\n", $item->name, $item->barcode, $item->cost;
  $self->store;
}

sub cart ($self) {
  my $cart = $self->carts->first(sub{!$_->finish});
  return $cart if $cart;
  warn "Starting new cart";
  push @{$self->carts}, Cart->new(store => $self);
  return $self->carts->first(sub{!$_->finish});
}

sub close ($self) {
  if (!$self->is_open) {
    warn sprintf "%s is already closed", $self->name;
  }
  else {
    my $items = $self->carts->reduce(sub { $a + $b->size }, 0);
    my $sales = $self->carts->reduce(sub { $a + $b->total }, Money(0));
    my $customers = $self->carts->size;
    warn sprintf "You sold %d items (%s) to %d customers.", $items, $sales, $customers;
    $self->store;
    $self->carts(undef);
    warn sprintf "%s is now closed!\n", $self->name;
  }
  # ReadMode 'normal';
}

sub dump ($self) {
  return unless $self->is_open(1);
  $self->inventory->each(sub {
    my $barcode = $_->barcode;
    warn sprintf "%-20s | %-30s | %10s | %3s | %3s", $_->barcode, $_->name, $_->cost, $_->inventory, $self->carts->map(sub { $_->items->grep(sub { $_->barcode eq $barcode })->size })->reduce(sub { $a + $b }, 0);
  });
  warn "\n";
}

sub edit_item ($self, $item) {
  warn sprintf "Editing %s (%s)", $item->name, $item->barcode;
  my $barcode = $item->barcode;
  warn "New name for barcode $barcode: ";
  my $name = 'Test'; #chomp(my $name = <STDIN>);
  $name = $item->name unless $name;
  warn "$name new cost: ";
  my $cost; #chomp(my $cost = <STDIN>);
  $cost = substr($cost, 0, 5);
  $cost =~ s/[^\d\.]//g;
  $cost = $item->cost unless looks_like_number($cost);
  warn "$name new quantity: ";
  my $qty; #chomp(my $qty = <STDIN>);
  $qty = substr($qty, 0, 5);
  $qty =~ s/\D//g;
  $qty = $item->inventory unless looks_like_number($qty);
  $self->inventory->first(sub{$_->barcode eq $barcode})->name($name)->cost($cost)->inventory($qty);
  warn sprintf "Updated %s (%s) for %s in inventory!\n", $item->name, $item->barcode, $item->cost;
  $self->store;
}

sub get_barcode ($self, $show=0) {
  # ReadMode 'noecho' unless $show;
  my $barcode = "%123"; #chomp(my $barcode = <STDIN>);
  #ReadMode 'normal' unless $show;
  $barcode = substr($barcode, 0, 20);
  $barcode = chr hex $barcode =~ s/^%%//r if $barcode =~ /^%%/;
  return $barcode;
}

sub in_stock ($self, $barcode) {
  return 1 if 1;
  warn sprintf "Sold out of ";
  return 0;
}

sub is_open ($self, $say=0) {
  if (defined $self->inventory && ref $self->inventory eq 'Mojo::Collection' && defined $self->carts && ref $self->carts eq 'Mojo::Collection') {
    return 1;
  }
  else {
    warn sprintf "%s is closed!  Come back later!\n", $self->name if $say;
    return 0;
  }
}

sub list ($self) {
  my $cart = $self->carts->first(sub{!$_->finish}) or return;
  my $c = 0;
  return unless $cart->items;
  $cart->items->each(sub {
    warn sprintf "%3d: %-20s %5s (%6s)", ++$c, $_->name, $_->cost, $cart->subtotal;
  });
}

sub load ($self) {
  warn sprintf "Loading %s inventory!", $self->name;
  $self->inventory(-e $self->file ? Storable::retrieve($self->file) : Mojo::Collection->new);
  return $self;
}

sub new {
  my $self = shift->SUPER::new(@_);
  warn sprintf "Welcome to %s!\n", $self->name;
  $self->is_open(1);
  return $self;
}

sub open ($self) {
  if ($self->is_open) {
    warn sprintf "%s is already open\n", $self->name;
  }
  else {
    $self->load;
    $self->carts(Mojo::Collection->new);
    warn sprintf "\n%s is now open!\n", $self->name if $self->is_open;
  }
}

sub remove_item ($self) {
  warn "Scan item to remove from inventory: ";
  my $barcode = $self->get_barcode(1);
  my $delete = 0;
  $self->inventory($self->inventory->reduce(sub {
    push @$a, $b unless $delete || $b->barcode eq $barcode;
    $delete = 1 if $b->barcode eq $barcode;
    return $a;
  }, Mojo::Collection->new));
  warn "Removed $barcode";
  $self->store;
}

sub store ($self) {
  warn sprintf "Storing %s inventory!", $self->name;
  Storable::store($self->inventory, $self->file);
  return $self;
}

1;