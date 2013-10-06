#!/usr/bin/env perl
use strict;
use warnings;

use Imager;
use ImageCutter;

my $cutter = ImageCutter->new(
    image => Imager->new( file => "t/images/text-with-extra-margin.png" )
);

$cutter->trim_edges;

$cutter->image->write( file => "/tmp/trim-edges.png" );
