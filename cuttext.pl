#!/usr/bin/env perl

=head1 USAGE

    cuttext.pl -o /dir/output -r receipt.json foo.png

=head1 DESCRIPTION

This program takes a image file, and cut it into smaller rectangles. The image
file is assumed to contain mostly text and having white background.

    - a rectangle should be at least 24x24 in size
    - a rectangle is discarded if it contains only one color (background)

The output recept contains the list of file names of the recantagles, and their
corresponding xy offset to the original image.

=cut

use v5.14;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";

use Getopt::Std;
my %opts;
getopts("o:r:", \%opts);
if ($opts{o} && @ARGV == 1) {
    cuttext($ARGV[0], $opts{o}, $opts{r});
    exit 0;
}
exit 1;

use File::Spec::Functions "catfile";
use JSON;

use Imager;
use ImageCutter;
use ImagerExt;

sub cuttext {
    my ($img_file, $output_dir, $output_receipt) = @_;
    unless( -d $output_dir)  {
        require File::Path;
        File::Path::make_path($output_dir);
    }

    my $margin = 4;
    my $img = ImagerExt->new( file => $img_file );
    my $row_groups = $img->text_row_groups;
    for (my $i = 0; $i < @$row_groups; $i++) {
        next if $row_groups->[$i][2];
        my $x = $img->crop(
            top    => $row_groups->[$i][0] - $margin ,
            bottom => $row_groups->[$i][1] + $margin
        );
        $x->write( file => "${output_dir}/$i.png" );

        my $y = $x->rotate(degrees => 90);
        my $col_groups = $y->text_row_groups;
        for (my $j = 0; $j < @$col_groups; $j++) {
            next if $col_groups->[$j][2];
            $y->crop(
                top    => $col_groups->[$j][0] - $margin ,
                bottom => $col_groups->[$j][1] + $margin
            )->rotate(degrees => 270)->write( file => "${output_dir}/$i-$j.png" );
        }
    }
    return;
}

