#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Encode qw(encode);

binmode(STDOUT, ':utf8');

sub show_bytes {
    my ($str, $encode) = @_;
    my $bytes = encode($encode, $str);

    print "文字列: $str\n";
    print "16進数: " . unpack('H*', $bytes) . "\n";
    print "\n";
}

sub show {
    my $encode = shift;

    print $encode."\n";
    show_bytes("a", $encode);
    show_bytes("あ", $encode);
    show_bytes("世界", $encode);
    show_bytes("🐶", $encode);
    show_bytes("🐱", $encode);
}

show('UTF-8');
show('Shift-JIS');
show('ASCII');
show('EUC-JP');
