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

system "convert", $input_file, qw(-contrast -enhance -sharpen 2x2 -resize 2000x2000), $shadowed;

my $cutter = ImageCutter->new( image => Imager->new(file => $shadowed) );
my $boxes = $cutter->cut_8connect_boxes;

make_path($output_dir) unless -d $output_dir;

$cutter->image->write( file => "${output_dir}/shadow.png" );

my $original_image   = Imager->new(file => $input_file);
my $ratio_horizontal = ($original_image->getheight / $cutter->image->getheight );
my $ratio_vertical   = ($original_image->getwidth  / $cutter->image->getwidth  );

for my $box (@$boxes) {
    my $b = $box->{box};
    my $b2 = {
        top    => ($b->{top}    - 1) * $ratio_horizontal,
        bottom => ($b->{bottom} + 1) * $ratio_horizontal,
        left   => ($b->{left}   - 1) * $ratio_vertical,
        right  => ($b->{right}  + 1) * $ratio_vertical,
    };
    $box->{box} = $b2;
    $box->{_box_shadow} = $b;

    my $img;
    if ($img = $original_image->crop(%$b2)) {
        $img->write(file => "${output_dir}/original-bbox-" . join(",", @{$b}{"top","right", "bottom","left"}) . ".png");
    }
    if ($img = $cutter->image->crop(%$b)) {
        $img->write(file => "${output_dir}/shadow-bbox-" . join(",", @{$b}{"top","right", "bottom","left"}) . ".png");
    }
}

open my $fh, ">", "${output_dir}/receipt.json";
say $fh JSON::to_json( $boxes, { pretty => 1 });

unlink $shadowed;
