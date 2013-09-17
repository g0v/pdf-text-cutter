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
use File::Basename "fileparse";

my $origin_file_name = $ARGV[0];

my ($file, $dir) = fileparse($origin_file_name);
my ($file_base, $file_suffix) = $file =~ m!\A(.+)\.([^.]+)\z!;

my $angle = `pamtilt $origin_file_name` =~ s/\n\z//r;

system("pgmdeshadow $origin_file_name | pnmrotate $angle > $dir/${file_base}.deshadow.deskew.pnm");

my $img = Imager->new( file => "$dir/${file_base}.deshadow.deskew.pnm" );
$img = $img->convert( preset => "grey" );

my $mama = ImageMama->new( image =>  $img );
$mama->cut_margin;
$mama->clean_outlier_pixels3;

$mama->image->write( file => $ARGV[1] );
