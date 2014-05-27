package Sereal::Milk::Document::Header;

use 5.10.1;

use Moo;
use MooX::StrictConstructor;

use Carp;
use autodie qw(read seek binmode);
use Sereal::Encoder::Constants qw(:all);

use Sereal::Milk::Document::Body;

require bytes;

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
  default => sub {    $_[0]->encoding_type eq SRL_PROTOCOL_ENCODING_SNAPPY_INCREMENTAL
                   || $_[0]->encoding_type eq SRL_PROTOCOL_ENCODING_SNAPPY
                 },
);

has user_data  => (
  is => 'rw',
);

sub load {
    my ($self) = @_;

    my $length = 0;

    my $fh = $self->_fh;
    my $original_pos = $fh->getpos;
    $fh->seek($self->_start_pos, 0);

    # magic
    $length += $fh->read(my $magic, SRL_MAGIC_STRLEN);
    $magic eq SRL_MAGIC_STRING
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
                Sereal::Milk::Document::Body->new( _fh => $fh,
                                                   _start_pos => $fh->getpos,
                                                 )->load()
          );
    }
    $fh->seek($opt_suffix_size, 1);

    $self->encoding_type() == SRL_PROTOCOL_ENCODING_SNAPPY_INCREMENTAL
      and $self->snappy_length(varint($fh, $length));

    $self->length($length);

    $fh->setpos($original_pos);
    $self;
}


sub varint {
    my $lshift = 0;
    my $val = 0;

    while (my $r = $_[0]->read(my $byte, 1)) {
        defined $_[1] and $_[1] += $r;
        $byte = ord($byte);
        $val += ($byte & 0x7F) << $lshift;
        $lshift += 7;
        $byte & 0x80
          or return $val
    }

    die "premature end of varint";

}

1;
