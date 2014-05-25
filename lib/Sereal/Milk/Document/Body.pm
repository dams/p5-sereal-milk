package Sereal::Milk::Document::Body;

use 5.10.1;

use Moo;

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


1;
