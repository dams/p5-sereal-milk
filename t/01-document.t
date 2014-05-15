use strict;
use warnings;

use Test::More;

use Sereal::Milk::Document;

use Sereal::Encoder;
my $encoder = Sereal::Encoder->new();

my $data = $encoder->encode("plop");

my $doc = Sereal::Milk::Document->new(source => \$data);

use Data::Dumper;

print Dumper($doc);
done_testing;
