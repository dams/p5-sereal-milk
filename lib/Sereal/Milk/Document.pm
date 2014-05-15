package Sereal::Milk::Document;

use 5.10.1;

use Moo;

use Carp;
use autodie qw(read seek binmode);

use Sereal::Milk::Document::Header;

=attr source

the source of the Sereal document. Can be either a filename, or a reference to
a scalar containing the document data.

=cut

has source => (
  is => 'ro',
  required => 1,
);

has _fh => (
  is => 'ro',
  lazy => 1,
  builder => sub {
    my ($self) = @_;
    my $source = $self->source;
    my $fh = IO::File->new($source, 'r')
      or croak "failed to open source '$source'";
    $fh->binmode(':raw');
    $fh;
  },
);

has _start_pos => (
  is => 'ro',
  default => sub { 0 },
);

has header => (
  is => 'ro',
  lazy => 1,
  builder => sub {
      my ($self) = @_;
      Sereal::Milk::Document::Header->new( _fh => $self->_fh,
                                           _start_pos => $self->_start_pos,
                                         );
  },
);

has body => (
  is => 'ro',
  lazy => 1,
  builder => sub {
      my ($self) = @_;
      Sereal::Milk::Document::Body->new( _fh => $self->_fh,
                                         _start_pos => $self->_start_pos,
                                       );
  },
);

sub BUILD {
    my ($self) = @_;
    $self->header->load;
}

1;
