package Sereal::Milk::Document::Body;

use 5.10.1;

use Moo;
use MooX::StrictConstructor;

use Carp;
use autodie qw(read seek binmode);
use Sereal::Encoder::Constants qw(:all);

has _fh => (
  is => 'ro',
  required => 1,
);

has _start_pos => (
  is => 'ro',
  required => 1,
);

has length => (
  is => 'rw',
  lazy => 1,
  builder => sub {
      my ($self) = @_;
          my $fh = $self->_fh;
    my $pos = $fh->getpos;
    $fh->seek($self->_start_pos, 0);

    $fh->setpos($pos);
    $self;

  }
);

has is_compressed => (
  is => 'ro',
  required => 1,
);

sub parse {
    my ($self) = @_;

    my $length = 0;

    my $fh = $self->_fh;
    my $original_pos = $fh->getpos;
    $fh->seek($self->_start_pos, 0);

    _parse_sv($fh);

    $fh->setpos($original_pos);

}

sub _parse_sv {
    my ($fh) = @_;
    my $length = 0;
    $length += $fh->read(my $tag, 1);
    
}

sub load {}

1;
