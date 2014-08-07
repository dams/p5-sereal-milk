package Sereal::Milk::Util;

use 5.10.1;

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(varint slurp);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

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

    croak "premature end of varint";

}

sub slurp {
    my ($fh, $length) = @_;
    if (!$length) {
        local $/;
        return scalar(<$fh>);
    }
    $fh->read(my $data, $length);
    return $data;
}
