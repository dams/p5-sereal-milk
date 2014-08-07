package Sereal::Milk::Document::Body;

use 5.10.1;

use Moo;
use MooX::StrictConstructor;

use Carp;
require bytes;
use autodie qw(read seek binmode);
use Sereal::Encoder 3.0;
use Sereal::Encoder::Constants qw(:all);

use Sereal::Milk::Util qw(:all);

use Scalar::Util qw(reftype);

has document => (
  is => 'ro',
  weak_ref => 1,
  required => 1,
);

has fh => (
  is => 'ro',
  required => 1,
);

has start_pos => (
  is => 'ro',
  required => 1,
);

has encoding_type => (
  is => 'ro',
  default => sub { SRL_PROTOCOL_ENCODING_RAW },
);

has _content_fh => (
  is => 'ro',
  lazy => 1,
  builder => sub {
      my ($self) = @_;
      $DB::single = 1;
      $self->encoding_type eq SRL_PROTOCOL_ENCODING_RAW
        and return $self->fh;
      if ($self->encoding_type eq SRL_PROTOCOL_ENCODING_SNAPPY) {
          my $fh = $self->fh;
          my $original_pos = $fh->getpos;
          $fh->seek($self->start_pos, 0);

          my $compressed_data = slurp($fh);
          require Compress::Snappy;
          my $uncompressed_data = Compress::Snappy::decompress($compressed_data);
          my $uncompressed_fh = IO::File->new(\$uncompressed_data, 'r+')
            or croak "failed to open body source";
          $uncompressed_fh->binmode(':raw');

          $fh->setpos($original_pos);
          return $uncompressed_fh;
      }
      if ($self->encoding_type eq SRL_PROTOCOL_ENCODING_SNAPPY_INCREMENTAL) {
          my $fh = $self->fh;
          my $original_pos = $fh->getpos;
          $fh->seek($self->start_pos, 0);

          my $compressed_length = varint($fh);
          my $compressed_data = slurp($fh, $compressed_length);
          require Compress::Snappy;
          my $uncompressed_data = Compress::Snappy::decompress($compressed_data);
          $self->_slurped_content($uncompressed_data);
          my $uncompressed_fh = IO::File->new(\$uncompressed_data, 'r+');
          $uncompressed_fh->binmode(':raw');

          $fh->setpos($original_pos);
          return $uncompressed_fh;
      }
      if ($self->encoding_type eq SRL_PROTOCOL_ENCODING_ZLIB) {
          my $fh = $self->fh;
          my $original_pos = $fh->getpos;
          $fh->seek($self->start_pos, 0);

          my $uncompressed_length = varint($fh);
          my $compressed_length = varint($fh);
          my $compressed_data = slurp($fh, $compressed_length);
          require Compress::Zlib;
          my $uncompressed_data = Compress::Zlib::uncompress($compressed_data);
          $self->_slurped_content($uncompressed_data);
          my $uncompressed_fh = IO::File->new(\$uncompressed_data, 'r+');
          $uncompressed_fh->binmode(':raw');
          $uncompressed_fh->seek(0, 0);

          $fh->setpos($original_pos);
          return $uncompressed_fh;
      }
      croak "encoding not supported";
  },
);

has _content_start_pos => (
  is => 'ro',
  lazy => 1,
  builder => sub {
      my ($self) = @_;
      $self->encoding_type eq SRL_PROTOCOL_ENCODING_RAW
        and return $self->start_pos;
      $self->encoding_type eq SRL_PROTOCOL_ENCODING_SNAPPY_INCREMENTAL
        and return 0;
      $self->encoding_type eq SRL_PROTOCOL_ENCODING_ZLIB
        and return 0;
      croak "encoding not supported";
  },
);

has length => (
  is => 'rw',
  lazy => 1,
  predicate => 1,

  builder => sub { bytes::length($_[0]->_slurped_content); }
);

has _slurped_content => (
  is => 'rw',
  lazy => 1,
  builder => sub {
      my ($self) = @_;
      my $fh = $self->_content_fh;
      my $original_pos = $fh->getpos;
      $fh->seek($self->_content_start_pos, 0);
      my $content = slurp($fh);

      $fh->setpos($original_pos);
      return $content;
  },
);

sub maybe_match_in_strings {
    my ($self, $regexp) = @_;
    $self->_slurped_content =~ $regexp
      and return 1;
    return;
    # we may have a match
#    $self->_fast_decoder->decode($data, my $structure);
#    _match_deeply_in_strings($structure, $regexp);

}

sub match_in_strings {
    my ($self, $regexp) = @_;
    $self->maybe_match_in_strings($regexp)
      or return;
    my $res = $self->_collect_strings_from_struct($self->document->_decoded_struct);
    

}

sub _collect_strings_from_struct {
    my ($self, $struct) = @_;

    my @res;

    my @stack = [ $struct, '$struct->', [] ];
    my %seen_refs;

    while (my ($ref, $path, $path2) = @{ shift(@stack) // [] }) {

        $seen_refs{$ref}++ and next;

        my $r = reftype($ref);

        ! defined $r
          and push(@res, [ $ref, $path, $path2 ]),
              next;

        $r eq 'HASH'   ?  push @stack, map [ $ref->{$_}, $path . "{$_}", [ @$path2, "H$_" ] ], keys %$ref     :
        $r eq 'ARRAY'  ?  push @stack, map [ $ref->[$_], $path . "[$_]", [ @$path2, "A$_" ] ], 0 .. @$ref - 1 :
        $r eq 'SCALAR' && push @stack, [ $$ref, '${' . $path . '}', [ @$path2, "R" ]];


    }
    return \@res;

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
