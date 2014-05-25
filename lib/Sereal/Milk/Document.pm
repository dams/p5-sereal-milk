package Sereal::Milk::Document;

use 5.10.1;

use Moo;

use Type::Params qw( compile );
use Types::Standard qw( Object InstanceOf slurpy );

use Carp;
use autodie qw(read seek binmode);

use Sereal::Milk::Document::Header;
use Sereal::Milk::Document::Body;

use Sereal::Decoder;

has _decoder => (
  is => 'ro',
  builder => sub { Sereal::Decoder->new(); },
);

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
    my $fh = IO::File->new($source, 'r+')
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

=method decode

Deserialize the document, and returns a Perl structure.

=cut

sub decode {
    my ($self) = @_;
    my $structure;

    use Mmap;
    mmap(my $temp, 0, PROT_READ, 0, $self->_fh, $self->_start_pos)
      or croak "mmap: $!";
    $self->_decoder->decode($temp, my $structure);
    munmap($temp)
      or die "munmap: $!";

    return $structure;
}

=method append

Appends one or more C<Sereal::Milk::Document> passed as argument.

=cut

sub append {
    state $check = compile( Object, slurpy ArrayRef[InstanceOf[__PACKAGE__]] );
    my ($self, $docs) = $check->(@_);

    # foreach my $doc (@$docs) {
#    $doc2->body->
}

1;
