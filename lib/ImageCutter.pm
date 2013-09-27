package ImageCutter;
use v5.14;
use Moo;
use Imager;
use ImageTester;

has image => (is => "rw", requried => 1);

with "ImageMunger";

sub looks_like_white {
    state $color_white = Imager::Color->new("#FFFFFF");
    my $color = shift;
    return 1 if $color_white->equals(other => $color, ignore_alpha => 1);

    my ($r,$g,$b,undef) = $color->rgba();

    # 229 = 255 * 0.9
    if ( $r > 229 && $g > 229 && $b > 229 ) {
        return 1;
    }

    return 0;
}

# return an ArrayRef[{ image => Imager, top => Int, bottom => Int }]
sub cut_by_grid {
    my ($self) = @_;
    my $output = [];
    my $img = $self->image;

    # $self->clean_outlier_pixels;
    # $self->image->write(file => "output/after.png");

    my $size_grid = 6;
    my $img_width = $img->getwidth();
    my $img_height = $img->getheight();
    my $color_white = Imager::Color->new("#FFFFFF");

    my $img_row;
    my ($row_top, $row_bottom) = (0, $size_grid);
    while ($row_bottom < $img_height) {
        if (!$img_row) {
            $row_top = $row_bottom + $size_grid;
            $row_bottom = $row_top + $size_grid;
            $img_row = $img->crop(top => $row_top, bottom => $row_bottom);
            say "Cut row: $row_top - $row_bottom";
        }

        my $tester = ImageTester->new( image => $img_row );

        if ($tester->bottom_edge_contains_only_background) {
            if ($tester->contains_only_background()) {
                $img_row = undef;
            }
            else {
                push @$output, {
                    image => $img_row,
                    margin => {
                        top => $row_top,
                        bottom => $row_bottom
                    }
                };

                $row_top = $row_bottom;
                $row_bottom = $row_top + $size_grid;
            }
        }
        else {
            $row_bottom += $size_grid;
            $img_row = $img->crop(
                top => $row_top,
                bottom => $row_bottom
            );
            say " expand row: $row_top - $row_bottom";
        }
    }

    push @$output, {
        image => $img_row,
        margin => {
            top => $row_top,
            bottom => $row_bottom
        }
    };
    return $output;
}

sub cut_text_lines {
    my $self = $_[0];
    my @ret;
    my $blank_line_groups = $self->blank_line_groups;
    for (my $i = 0; $i < @$blank_line_groups-1 ; $i++) {
        my $lgi = $blank_line_groups->[$i];
        my $lgj = $blank_line_groups->[$i+1];
        my %crop = (
            top => $lgi->{bottom},
            bottom => $lgj->{top}
        );
        my $line = $self->image->crop(%crop);
        push @ret, {
            image => $line,
            box => \%crop
        };
    }
    return \@ret;
}

sub blank_line_groups {
    my $self = $_[0];

    my $img = $self->image;
    my $img_width = $img->getwidth();
    my $img_height = $img->getheight();

    my $color_white = Imager::Color->new("#FFFFFF");

    # find groups of contiguous rows that are almost white.
    my $line_group;
    my @line_groups;

    # XXX: magic number
    my $margin_ratio = $img_width > 100 ? 0.1 : 0;
    my $margin = int($img_width * $margin_ratio);

    for my $row ( 0.. $img_height - 1 ) {
        my $white_count = 0;
        for my $col ($margin .. ($img_width-$margin-1)) {
            my $c = $img->getpixel( x => $col, y => $row );
            if ($c->equals(other => $color_white, ignore_alpha => 1)) {
                $white_count++;
            }
        }

        my $is_blank = ( $white_count == $img_width - 2 * $margin );
        # my $almost_blank = ( ($white_count / $img_width) > 0.999 );

        if ( $is_blank ) {
            if ($line_group) {
                $line_group->{ bottom } = $row;
            }
            else {
                $line_group = { top => $row };
            }
        }
        else {
            if ($line_group) {
                if ($line_group->{bottom}) {
                    push @line_groups, $line_group;
                }
                $line_group = undef;
            }
        }
    }

    return \@line_groups;
}

sub cut_text_rectangles  {
    my $self = $_[0];

    my @ret;
    my $rowcut = $self->cut_text_lines;

    for my $o (@$rowcut) {
        my $x = $self->new( image => $o->{image}->copy->rotate( right => 90 ) );
        my $colcut = $x->cut_text_lines;
        for my $p (@$colcut) {
            my $cut = $p->{image}->copy->rotate( right => 270 );
            push @ret, {
                image => $cut,
                box => {
                    top    => $o->{box}{top},
                    bottom => $o->{box}{bottom},
                    left   => $p->{box}{top},
                    right  => $p->{box}{bottom},
                }
            }
        }
    }

    return \@ret;
}

sub cut_out_text_box {
    my $self = $_[0];
    my $img = $self->image;
    my $img_width = $img->getwidth();
    my $img_height = $img->getheight();

    my $scanned = {};
    my %boxes;
    for my $y (0..$img_height-1) {
        my $x = 0;
        while($x < $img_width) {
            if ($scanned->{$x}{$y}) {
                $x += 1;
                next;
            }

            my $px = $img->getpixel( x => $x, y => $y );
            $scanned->{$x}{$y} = 1;
            if( looks_like_white($px) ) {
                $x += 1;
            } else {
                my $box = $self->box_containing_connected_pixels_from(x => $x, y => $y);
                my $k  = join ",", @{$box}{"top","bottom","left","right"};
                $boxes{$k} ||= { box => $box };
                $x = 1+$box->{right};

                for my $x_ ($box->{left}..$box->{right}) {
                    for my $y_ ($box->{top}..$box->{bottom}) {
                        $scanned->{$x_}{$y_} = 1;
                    }
                }
            }
        }
    }
    say "Box count: " . values(%boxes);
    return [ values %boxes ];
}

sub box_containing_connected_pixels_from {
    my ($self, %args) = @_;
    my ($x,$y) = @args{"x", "y"};

    my $box = { top => $y, bottom => $y, left => $x, right => $x };
    my $img = $self->image;
    my $anchor_pixel = $img->getpixel(x=>$x, y=>$y);

    my @stack = ([$x,$y]);
    my $scanned = {};
    while(@stack) {
        my $p = shift @stack;
        my ($x,$y) = @$p;
        next if $scanned->{$x}{$y};
        my $px = $img->getpixel(x => $x, y => $y);
        $scanned->{$x}{$y} = 1;
        if ( $px && !looks_like_white($px) ) {
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
    }

    return $box;
}

1;
