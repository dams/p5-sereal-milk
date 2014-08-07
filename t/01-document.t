use strict;
use warnings;

use Test::More;

use Sereal::Milk::Document;

use Sereal::Encoder qw(SRL_ZLIB);
my $encoder = Sereal::Encoder->new();
my $encoder_zlib = Sereal::Encoder->new( { compress => SRL_ZLIB,
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
    my $data = $encoder_zlib->encode([ "a" x 500, { key => "plip" x 500 . "plop" . "foobarbaz", a => [ f => g => h => { 1 => [ "r", "foo" ]}] } ]);

    open my $out, '>plop.srl';
    binmode($out);
    print $out $data;

    my $doc = Sereal::Milk::Document->new(source => \$data);

#    is($doc->body->length, 1, "body has right size");
    use Data::Dumper;

    print Dumper($doc);
    print Dumper($doc->body);
    
    my $body_fh = $doc->body->_content_fh;
    my $content = do { local $/; scalar(<$body_fh>) };
    print Dumper($content);
    print Dumper($doc->body->length);

    print STDERR Dumper($doc->body->maybe_match_in_strings(qr/foobar/));
    print STDERR Dumper($doc->body->match_in_strings(qr/foobar/));

    # my $raw_data = $doc->_get_uncompressed_body_data();
    # print Dumper($raw_data);
#    is($doc1->decode(""), "plopplip");

}

done_testing;
