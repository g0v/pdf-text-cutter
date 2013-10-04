#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;

system "convert", $ARGV[0],
    # -density              => "150x150",
    # -resize               => "200%",
    -fill                 => "white",
    -level                => "20%,80%,1.0",
    "-sigmoidal-contrast" => "30,50%",
    -sharpen              => "0x2",
    -deskew               => "40%",
    -fuzz                 => "75%",
    -background           => "black",
    -bordercolor          => "black",
    -border               => "1x1",
    -floodfill            => "+0,+0", "black",
    -fuzz                 => "25%",
    qw( -trim -despeckle ),
    $ARGV[1];

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

