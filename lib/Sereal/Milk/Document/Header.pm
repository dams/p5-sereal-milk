package Sereal::Milk::Document::Header;

use 5.10.1;

use Moo;

use Carp;
use autodie qw(read seek binmode);
use Sereal::Encoder::Constants qw(:all);

use Sereal::Milk::Document::Body;

has _fh => (
  is => 'ro',
  required => 1,
);

has _start_pos => (
  is => 'ro',
  required => 1,
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

has user_data  => (
  is => 'rw',
);

sub load {
    my ($self) = @_;
    my $fh = $self->_fh;
    my $pos = $fh->getpos;
    $fh->seek($self->_start_pos, 0);

    # magic
    $fh->read(my $magic, SRL_MAGIC_STRLEN);
    $magic eq SRL_MAGIC_STRING
      or croak "invalid magic";

    # version-type
    $fh->read(my $version_type, 1);
    $self->proto_version( ord($version_type) & SRL_PROTOCOL_VERSION_MASK);
    $self->encoding_type( ord($version_type) & SRL_PROTOCOL_ENCODING_MASK);

    # opt_suffix
    my $opt_suffix_size;
    if ( ($opt_suffix_size = varint($fh)) && $self->proto_version >= 2 ) {
        $fh->read(my $bitfield, 1);
        $opt_suffix_size--;
        ord($bitfield) & SRL_PROTOCOL_HDR_USER_DATA
          and $self->user_data(
                Sereal::Milk::Document::Body->new( _fh => $fh,
                                                   _start_pos => $fh->get_pos,
                                                 )->load()
          );
    }
    $fh->seek($opt_suffix_size, 1);

    $fh->setpos($pos);
    $self;
}


sub varint {
    my ($fh) = @_;
    my $lshift = 0;
    my $val = 0;

    while ($fh->read(my $byte, 1)) {
        $byte = ord($byte);
        $val += ($byte & 0x7F) << $lshift;
        $lshift += 7;
        $byte & 0x80
          or return $val
    }

    die "premature end of varint";

}


1;
