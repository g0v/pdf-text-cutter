#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;

use File::Basename qw<dirname basename>;
use List::Util qw<sum>;
use Imager;

sub sumrgba {
    return $_[0] + ($_[1] << 8) + ($_[2] << 16) + ($_[3] << 24)
}

my $input_file = $ARGV[0];
my $output_file = dirname($input_file) . "/sortrow_" . basename($input_file);

my $img = Imager->new(file => $input_file) or die Imager->errstr;

my $h = $img->getheight;
for my $y (0..$h-1) {
    my @pixels = $img->getscanline( y => $y );
    @pixels = map { $_->[1] } sort {
        $a->[0][0] <=> $b->[0][0] ||
        $a->[0][1] <=> $b->[0][1] ||
        $a->[0][2] <=> $b->[0][2] ||
        $a->[0][3] <=> $b->[0][3]
    } map {[ [$_->rgba], $_]} @pixels;
    $img->setscanline( y => $y, pixels => \@pixels );
}

$img->write( file => $output_file );
say $output_file;
