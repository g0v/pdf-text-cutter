#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;

    # -density              => "150x150",
    # -resize               => "200%",
#     qw( -trim -despeckle ),
    # -deskew               => "40%",

my ($input, $output) = @ARGV;

system "convert", $input,
    "-sigmoidal-contrast" => "30,50%",
    -fill => "white",
    -background           => "black",
    -bordercolor          => "black",
    -border               => "10x10",
    -fuzz                 => "75%",
    -floodfill            => "+0+0", "black",
    qw (-trim +repage ),
    "/tmp/proc.$$.png";

system "convert", "/tmp/proc.$$.png",
    -background => "white",
    -fill                 => "white",
    -deskew     => "40%",
    qw (-trim +repage ),
    -level                => "20%,80%,1.0",
    -sharpen              => "0x2",
    $output;

unlink "/tmp/proc.$$.png";

# my ($w, $h) = split " ", `convert $ARGV[1] -format '%[fx:w] %[fx:h]' info:`;

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

