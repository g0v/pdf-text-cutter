#!/usr/bin/env perl
use v5.14;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use Imager;
use ImageTester;

-f $ARGV[0] or die;

my $img = Imager->new( file => $ARGV[0] ) or die Imager->errstr;

my $tester = ImageTester->new( image => $img );
my $bg_color = $tester->guess_background_color;
say $bg_color;
