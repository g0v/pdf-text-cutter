#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;
use JSON;
use Imager;
use File::Path qw(make_path);

use FindBin;
use lib "$FindBin::Bin/lib";
use ImageCutter;

@ARGV == 2 or die <<"ERROR";

Usage - $0 input.png output_dir/

ERROR

my ($input_file, $output_dir) = @ARGV;

my $shadowed = "/tmp/$$.shadowed.png";

system "convert", "-statistic", "minimum", "3x3", $input_file, $shadowed;

my $cutter = ImageCutter->new( image => Imager->new(file => $shadowed) );
my $boxes = $cutter->cut_8connect_boxes;

make_path($output_dir) unless -d $output_dir;

my $original_image = Imager->new(file => $input_file);
for (@$boxes) {
    my $b = $_->{box};
    my $img = $original_image->crop(%$b);
    $img->write(file => "${output_dir}/bbox-" . join(",", @{$b}{"top","right", "bottom","left"}) . ".png");
}

open my $fh, ">", "${output_dir}/receipt.json";
say $fh JSON::to_json( $boxes, { pretty => 1 });

unlink $shadowed;
