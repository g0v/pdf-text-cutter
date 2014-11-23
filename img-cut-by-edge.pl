#!/usr/bin/env perl
use v5.18;
use strict;
use warnings;

use Getopt::Std;
use Imager;
use Imager::Color;

sub looks_like_white {
    state $color_white = Imager::Color->new(255, 255, 255);
    my $color = shift;
    return 1 if $color_white->equals(other => $color, ignore_alpha => 1);
    my ($r,$g,$b,undef) = $color->rgba();
    # 229 = 255 * 0.9
    if ( $r > 229 && $g > 229 && $b > 229 ) {
        return 1;
    }
    return 0;
}

sub start_cutting {
    my $ctx = shift;

    my $COLOR_BLACK = Imager::Color->new(0,0,0);
    my $img        = $ctx->{input};
    my $img_width  = $img->getwidth();
    my $img_height = $img->getheight();
    my $img_copy   = $img->copy;
    my $scanned = {};
    my %boxes;
    for my $y (0..$img_height-1) {
        my $x = 0;
        while ($x < $img_width) {
            my $mask_px = $ctx->{mask}->getpixel( x => $x, y => $y );
            if ( $scanned->{$x}{$y} || $mask_px->equals(other => $COLOR_BLACK, ignore_alpha => 1 ) ) {
                $x += 1;
                next;
            }
            my $box = { top => $y, bottom => $y, left => $x, right => $x };
            my @stack = ([$x,$y]);
            while (@stack) {
                my $p = shift @stack;
                my ($x,$y) = @$p;
                next if $scanned->{$x}{$y};
                my $px = $img->getpixel(x => $x, y => $y);
                $scanned->{$x}{$y} = 2;
                next unless $px;
                next if looks_like_white($px);
                $scanned->{$x}{$y} = 1;
                $box->{top}    = $y if $box->{top}    > $y;
                $box->{bottom} = $y if $box->{bottom} < $y;
                $box->{left}   = $x if $box->{left}   > $x;
                $box->{right}  = $x if $box->{right}  < $x;
                push(@stack, [$x+1, $y])   unless $scanned->{$x+1}{$y};
                push(@stack, [$x-1, $y])   unless $scanned->{$x-1}{$y};
                push(@stack, [$x, $y+1])   unless $scanned->{$x}{$y+1};
                push(@stack, [$x, $y-1])   unless $scanned->{$x}{$y-1};
                push(@stack, [$x+1, $y+1]) unless $scanned->{$x+1}{$y+1};
                push(@stack, [$x+1, $y-1]) unless $scanned->{$x+1}{$y-1};
                push(@stack, [$x-1, $y+1]) unless $scanned->{$x-1}{$y+1};
                push(@stack, [$x-1, $y-1]) unless $scanned->{$x-1}{$y-1};
            }
            if ($box->{right} > $box->{left} && $box->{bottom} > $box->{top}) {
                my $k  = join ",", @{$box}{"left","top","right","bottom"};
                $boxes{$k} ||= { box => $box };
                $x = 1+$box->{right};
                for my $x_ (keys %{$box->{scanned}}) {
                    for my $y_ (keys %{$box->{scanned}{$x_}}) {
                        $scanned->{$x_}{$y_} = 1;
                    }                    
                }

                if (my $box_img = $img->crop(%$box)) {
                    $box_img->write(file => "$ctx->{output}/box-$k.png");
                    $img_copy->box( box => [@{$box}{"left","top","right","bottom"}], filled => 0, color => "green");
                }
            }
        }
    }
    $img_copy->write( file => "$ctx->{output}/all.png" );
    # $ctx->{boxes} = [ values %boxes ];
    # for my $id (keys %boxes) {
    #     my $box = $boxes{$id};
    #     my $box_img = $img->crop(%$box);
    #     $box_img->write(file => "$ctx->{output}/box-$id.png");
    # }
}

sub main {
    my $ctx = shift;
    die "Invalid params" unless -f $ctx->{input} && -f $ctx->{mask} && -d $ctx->{output};

    $ctx->{input} = Imager->new( file => $ctx->{input} ) or die Imager->errstr;
    $ctx->{mask}  = Imager->new( file => $ctx->{mask} )  or die Imager->errstr;

    start_cutting($ctx);
}

my %opts;
getopts('i:o:m:', \%opts);
@opts{qw<input output mask>} = @opts{qw<i o m>};
main(\%opts);
