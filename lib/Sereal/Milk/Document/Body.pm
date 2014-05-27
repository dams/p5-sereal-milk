package Sereal::Milk::Document::Body;

use 5.10.1;

use Moo;
use MooX::StrictConstructor;

use Carp;
use autodie qw(read seek binmode);
use Sereal::Encoder::Constants qw(:all);
use Sereal::Decoder;

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

# has _fast_decoder => (
#   is => 'ro',
#   builder => sub {
#     Sereal::Decoder->new({ no_bless_objects => 1, }
#                         );
#   },
# );

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

sub maybe_match_in_strings {
    my ($self, $regexp) = @_;
    my $data = _slurp($self->_fh);
    $data =~ $regexp
      or return;

    return 1;
    # we may have a match
#    $self->_fast_decoder->decode($data, my $structure);
#    _match_deeply_in_strings($structure, $regexp);

}

sub match_in_strings {
    my ($self, $regexp) = @_;
    my $data = _slurp($self->_fh);
    $data =~ $regexp
      or return;

    # we may have a match
    $self->_fast_decoder->decode($data, my $structure);
    _match_deeply_in_strings($structure, $regexp);

}

sub _slurp {
    my ($fh, $length) = @_;
    if (!$length) {
        local $/;
        return scalar(<$fh>);
    }
    $fh->read(my $data, $length);
    return $data;
}

# my $regexp
# sub _match_deeply_in_strings {
#     my ($s, $regexp) = @_;
#     my $r = ref $s;
#     $r or $coderef->($s);
#     if ($r eq 'ARRAY') {
#         _deep_walk($_) foreach @$s;
#     } elsif ($r eq 'HASH') {
#         foreach my $k (keys %$s) {
#             $coderef->($s);
#             $s->{$k}
#         }
#     }
# }

1;
