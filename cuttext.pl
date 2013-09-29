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
if ($opts{o} && ($opts{r} && (!-f $opts{r} || $opts{r} eq "-")) && @ARGV == 1) {
    cuttext($ARGV[0], $opts{o}, $opts{r});
    exit 0;
}
exit 1;

use File::Spec::Functions "catfile";
use JSON;
use Imager;
use ImageCutter;

sub cuttext {
    my ($img_file, $output_dir, $output_receipt) = @_;

    unless( -d $output_dir)  {
        require File::Path;
        File::Path::make_path($output_dir);
    }

    my $image = Imager->new( file => $img_file ) or die Imager->errstr;
    # $image->filter(type=>"autolevels", lsat=>0.2, usat=>0.2);

    my $cutter = ImageCutter->new( image => $image );

    my $o = $cutter->cut_text_lines;
    # my $o = $cutter->cut_out_text_box;

    my $receipt = [];
    my $i = 0;
    for (@$o) {
        if (!$_->{image} && $_->{box}) {
            if ($_->{box}{right} > $_->{box}{left} && $_->{box}{bottom} > $_->{box}{top}) {
                $_->{image} = $image->crop(%{ $_->{box} });
            }
        }

        next if (!$_->{image});

        my $r = {
            filename => (my $filename = catfile($output_dir, sprintf("%08d", $i++) . ".png")),
            box => $_->{box}
        };
        $_->{image}->write(file => $filename);
        push @$receipt, $r;
    }

    my $fh;

    if ($opts{r} eq "-") {
        $fh = \*STDOUT
    }
    else {
        open $fh, ">", $output_receipt;
    }
    print $fh JSON->new->utf8->pretty->encode($receipt);
}
