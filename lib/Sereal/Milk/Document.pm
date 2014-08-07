package Sereal::Milk::Document;

use 5.10.1;

use Moo;
use MooX::StrictConstructor;

use Type::Params qw( compile );
use Types::Standard qw( Object InstanceOf ArrayRef slurpy );

use Carp;
use autodie qw(read seek binmode);

use Sereal::Milk::Document::Header;
use Sereal::Milk::Document::Body;

use Sereal::Milk::Util qw(:all);

use Sereal::Decoder qw(sereal_decode_with_object);

has _decoder => (
  is => 'ro',
  lazy => 1,
  builder => sub { Sereal::Decoder->new(); },
);

has _slurped_content => (
  is => 'ro',
  lazy => 1,
  builder => sub {
      my ($self) = @_;
      my $fh = $self->_fh;
      my $original_pos = $fh->getpos;
      $fh->seek($self->_start_pos, 0);
      my $content = slurp($fh);

      $fh->setpos($original_pos);
      return $content;
  },
);

has _decoded_struct => (
  is => 'ro',
  lazy => 1,
  builder => sub {
      my ($self) = @_;
      my $structure;
      sereal_decode_with_object($self->_decoder, $self->_slurped_content, $structure);
      return $structure;
  },
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
      Sereal::Milk::Document::Header->new( fh => $self->_fh,
                                           start_pos => $self->_start_pos,
                                         );
  },
);

has body => (
  is => 'ro',
  lazy => 1,
  builder => sub {
      my ($self) = @_;
        $DB::single = 1;
      my $start_pos = $self->_start_pos + $self->header->length;
      Sereal::Milk::Document::Body->new( fh => $self->_fh,
                                         start_pos => $start_pos,
                                         encoding_type => $self->header->encoding_type,
                                         document => $self,
                                       );
  },
);



=method decode

Deserialize the document, and returns a Perl structure.

=cut

sub decode {
    my ($self) = @_;
    my $structure;

#    $self->_decoder->decode($temp, my $structure);

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
