#!/usr/bin/env perl

=head1 USAGE

    cutpdf.pl -o /dir/output -r receipt.json foo.pdf

=cut

use v5.14;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";

use File::Path "make_path";
use File::Basename "basename";
use Getopt::Std;

my %opts;
getopts("o:r:", \%opts);

$opts{o} or die "`-o dir/` is required";
make_path($opts{o}) unless -d $opts{o};

my $pdffile = $ARGV[0] or die;
my $pdfoutputbase = basename($pdffile, ".pdf", ".PDF");
my $pdfoutput = $opts{o}."/".$pdfoutputbase."/page";
make_path($opts{o}."/".$pdfoutputbase);

system("pdftoppm", "-r", "300", $pdffile, $pdfoutput);

system "parallel", $^X, "preprocess.pl", "{}", "{.}.png", ":::", <$pdfoutput-*.ppm>;
system "parallel", $^X, "cuttext.pl", "-o", "{.}", "-r", "{.}/receipt.json", "{}", ":::", <$pdfoutput-*.png>;
