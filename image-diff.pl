#!/usr/bin/env perl
use v5.14;
use strict;
use Imager;

@ARGV == 2 or die;

my @imgs = map { Imager->new(file => $_) } @ARGV;

my $diff = $imgs[0]->difference(other => $imgs[1]);

$diff->write(file => "/tmp/diff.png");
