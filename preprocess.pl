#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;

system "convert", $ARGV[0], qw( -white-threshold 75% -black-threshold 75% -background black -deskew 40% -despeckle  -bordercolor black -border 1x1 -fuzz 75% -fill white -floodfill), "+0,+0", qw( black -fuzz 25% -trim ), $ARGV[1];

# use FindBin;
# use lib "$FindBin::RealBin/lib";

# package ImageMama;
# use Moo;
# has image => (
#     is => "rw",
#     required => 1
# );

# with "ImageMunger";

# package main;
# use Imager;
# use File::Basename "fileparse";
# my $origin_file_name = $ARGV[0];
# my ($file, $dir) = fileparse($origin_file_name);
# my ($file_base, $file_suffix) = $file =~ m!\A(.+)\.([^.]+)\z!;
# my $angle = `pamtilt $origin_file_name` =~ s/\n\z//r;
# system("pgmdeshadow $origin_file_name | pnmrotate -background '#fff' $angle | pnmtopng > $dir/${file_base}.deshadow.deskew.png");

# my $img = Imager->new( file => "$dir/${file_base}.deshadow.deskew.png" );
# $img = $img->convert( preset => "grey" );
# my $mama = ImageMama->new( image =>  $img );
# $mama->cut_margin;
# # $mama->clean_outlier_pixels3;
# $mama->image->write( file => $ARGV[1] );

