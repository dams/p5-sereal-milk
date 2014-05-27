use strict;
use warnings;

use Test::More;

use Sereal::Milk::Document;

use Sereal::Encoder;
my $encoder = Sereal::Encoder->new();
my $encoder_snappy = Sereal::Encoder->new( { snappy_incr => 1,
                                             snappy_threshold => 0,
                                           }
                                         );

# {
#     my $data1 = $encoder->encode("plop");
#     my $data2 = $encoder->encode("plip");

#     my $doc1 = Sereal::Milk::Document->new(source => \$data1);
#     my $doc2 = Sereal::Milk::Document->new(source => \$data2);

#     use Data::Dumper;
#     print Dumper($doc1);

# #    $doc1->append($doc2);
    
# #    is($doc1->decode(""), "plopplip");

# }

# {
#     my $data = $encoder->encode("a");
#     my $doc = Sereal::Milk::Document->new(source => \$data);

# #    is($doc->body->length, 1, "body has right size");
#     use Data::Dumper;
#     print Dumper($doc);

    
# #    is($doc1->decode(""), "plopplip");

# }

{
    my $data = $encoder_snappy->encode("a" x 500);
    my $doc = Sereal::Milk::Document->new(source => \$data);

#    is($doc->body->length, 1, "body has right size");
    use Data::Dumper;
    print Dumper($doc->header->encoding_type_is_snappy);

#    is($doc1->decode(""), "plopplip");

}

done_testing;
