#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";

package ImageMama;
use Moo;
has image => (
    is => "rw",
    required => 1
);

with "ImageMunger";

package main;
use Imager;

my $img = Imager->new( file => $ARGV[0]);
$img = $img->convert( preset => "grey" );
$img->write( file => "/tmp/grey.png" );

my $mama = ImageMama->new( image =>  $img );
$mama->cut_margin;
$mama->clean_cutlines;
$mama->clean_outlier_pixels2;

$mama->image->write( file => $ARGV[1] );
