use strict;
use warnings;

use Test::More;

use Sereal::Milk::Document;

use Sereal::Encoder;
my $encoder = Sereal::Encoder->new();

{
    my $data1 = $encoder->encode("plop");
    my $data2 = $encoder->encode("plip");

    my $doc1 = Sereal::Milk::Document->new(source => \$data1);
    my $doc2 = Sereal::Milk::Document->new(source => \$data2);

    use Data::Dumper;
    print Dumper($doc1);

    $doc1->append($doc2);
    
    is($doc1->decode(""), "plopplip");

}

done_testing;
