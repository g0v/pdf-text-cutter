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

my $file = $ARGV[0] or die;
my ($basename) = $file =~ m{/([^/]+)\.[a-z]{3}\z}i;

my $outputbase = "$opts{o}/$basename";

if (-d $outputbase) {
    say "Output dir already exists: $outputbase";
    exit;
}

make_path($outputbase);

system qw(convert -density 300), $file, $outputbase."/page.png";

my @pages = <$outputbase/*.png>;

# Clear black borders and enhance black/white
system "parallel",
    'mogrify -sigmoidal-contrast 30,50% -fill white -bordercolor black -border 1x1 -fuzz 75% -floodfill +0+0 black -trim -level 20%,80%,1.0 -sharpen 2 {}',
    ':::',
    @pages;

# Deskew
system "parallel",
    'mogrify -background white -fill white -deskew 40% -trim {}',
    ':::',
    @pages;

# Remove long horizontal/vertical lines (tabular/cell border)
system 'parallel', "sh $FindBin::Bin/image-remove-lines.sh {}", ':::', @pages;

# cutting
system "parallel", $^X, "cut-text-with-8connect.pl", "{}", "$opts{o}/{/.}", ":::", <$outputbase/page*.png>;
