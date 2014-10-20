#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;

use File::Basename qw<dirname basename>;
use List::Util qw<sum>;
use Imager;
use Imager::Color;

my $input_file = $ARGV[0];
my $output_file = dirname($input_file) . "/mark-delimiting-scanlines_" . basename($input_file);

my $img = Imager->new(file => $input_file) or die Imager->errstr;

;
my @delimiter_line = ( Imager::Color->new(0,0,255) ) x $img->getwidth;

my $h = $img->getheight;
for my $y (0..$h-1) {
    my @pixels = $img->getscanline( y => $y );

    my $max_len = 1;
    my $streak_start = 0;
    my $streak_end = 0;

    for my $i (1..$#pixels) {
        my $px = $pixels[$i];
        if ($px->equals( other => $pixels[$i-1])) {
            $streak_end = $i;
        } else {
            my $l = $streak_end - $streak_start + 1;
            $max_len = $l if $max_len < $l;
            $streak_start = $i;
            $streak_end   = $i;
        }
    }
    my $l = $streak_end - $streak_start + 1;
    $max_len = $l if $max_len < $l;

    if ($max_len / @pixels > 0.5) {
        $img->setscanline( y => $y, pixels => \@delimiter_line );
    }
}

$img->write( file => $output_file );
say $output_file;
