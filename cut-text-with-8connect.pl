#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;
use JSON;
use Imager;

use FindBin;
use lib "$FindBin::Bin/lib";
use ImageCutter;

my $file = shift or die;

my $shadowed = "/tmp/$$.shadowed.png";

system "convert", "-statistic", "minimum", "8x8", $file, $shadowed;

my $cutter = ImageCutter->new( image => Imager->new(file => $shadowed) );
my $boxes = $cutter->cut_out_text_box;

my $output_dir = "/tmp/boxes";
mkdir($output_dir) unless -d $output_dir;

my $original_image = Imager->new(file => $file);
for (@$boxes) {
    my $b = $_->{box};
    my $x = $original_image->crop(%$b);
    $x->write(file => "${output_dir}/bbox-" . join(",", @{$b}{"top","bottom","left","right"}) . ".png");
}

open my $fh, ">", "${output_dir}/box.json";
say $fh JSON::to_json( $boxes, { pretty => 1 });

unlink $shadowed;
