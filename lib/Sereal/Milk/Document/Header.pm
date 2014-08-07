package Sereal::Milk::Document::Header;

use 5.10.1;

use Moo;
use MooX::StrictConstructor;

use Carp;
use autodie qw(read seek binmode);
use Sereal::Encoder 3.0;
use Sereal::Encoder::Constants qw(:all);

use Sereal::Milk::Document::Body;

use Sereal::Milk::Util qw(:all);

use Types::Standard qw(InstanceOf);

has fh => (
  is => 'ro',
  required => 1,
);

has start_pos => (
  is => 'ro',
  required => 1,
);

has length => (
  is => 'rw',
);

has magic => (
  is => 'rw',
);

has proto_version => (
  is => 'rw',
);

has encoding_type => (
  is => 'rw',
);

has snappy_length => (
  is => 'rw',
);

has encoding_type_is_snappy => (
  is => 'ro', lazy => 1,
  default => sub { $_[0]->encoding_type eq SRL_PROTOCOL_ENCODING_SNAPPY_INCREMENTAL },
);

has encoding_type_is_zlib => (
  is => 'ro', lazy => 1,
  default => sub { $_[0]->encoding_type eq SRL_PROTOCOL_ENCODING_ZLIB },
);

has user_data  => (
  is => 'rw',
  isa => InstanceOf['Sereal::Milk::Document::Body']
);

sub load {
    my ($self) = @_;

    my $length = 0;

    my $fh = $self->fh;
    my $original_pos = $fh->getpos;
    $fh->seek($self->start_pos, 0);

    # magic
    $length += $fh->read(my $magic, SRL_MAGIC_STRLEN);
    $magic eq SRL_MAGIC_STRING || $magic eq SRL_MAGIC_STRING_HIGHBIT
      or croak "invalid magic";

    # version-type
    $length += $fh->read(my $version_type, 1);
    $self->proto_version( ord($version_type) & SRL_PROTOCOL_VERSION_MASK);
    $self->encoding_type( ord($version_type) & SRL_PROTOCOL_ENCODING_MASK );

    # opt_suffix
    my $opt_suffix_size;
    if ( ($opt_suffix_size = varint($fh, $length)) && $self->proto_version >= 2 ) {
        $length += $fh->read(my $bitfield, 1);
        $opt_suffix_size--;
        ord($bitfield) & SRL_PROTOCOL_HDR_USER_DATA
          and $self->user_data(
                Sereal::Milk::Document::Body->new( fh => $fh,
                                                   start_pos => $self->start_pos + $length,
                                                 )
          );
    }
    $fh->seek($opt_suffix_size, 1);

    $self->length($length);

    $fh->setpos($original_pos);
    $self;
}

sub BUILD { $_[0]->load; }

#    $self->encoding_type() == SRL_PROTOCOL_ENCODING_SNAPPY_INCREMENTAL
#      and $self->snappy_length(varint($fh, $length));





1;
