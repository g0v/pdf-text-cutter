package ImageCutter;
use v5.14;
use Moo;
use Imager;
use ImageTester;

has image => (is => "rw", requried => 1);

with "ImageMunger";

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

    my $img = $self->image;
    my $img_width = $img->getwidth();
    my $img_height = $img->getheight();

    my $color_white = Imager::Color->new("#FFFFFF");

    # find groups of contiguous rows that are not completely white.
    my $line_group;
    my @line_groups;
    my $previous_line_is_blank = 1;

    for my $row ( 0.. $img_height - 1 ) {
        my $white_count = 0;
        for my $col (0 .. $img_width-1) {
            my $c = $img->getpixel( x => $col, y => $row );
            # say "$row,$col " . join(",", $c->rgba) . " <=> " . join(",", $color_white->rgba);
            if ($c->equals(other => $color_white, ignore_alpha => 1)) {
                $white_count++;
            }
        }

        my $almost_blank = ((100 * $white_count / $img_width) > 99.5);

        if ( !$almost_blank ) {
            if ($previous_line_is_blank) {
                $line_group = { top => $row };
            }
        }
        else {
            if (!$previous_line_is_blank) {
                $line_group->{bottom} = $row;
                push @line_groups, $line_group;
            }
        }

        # $previous_line_is_blank = ($white_count == $img_width);
        $previous_line_is_blank = $almost_blank;
    }

    my @ret;
    for my $lg (@line_groups) {
        next if $lg->{bottom} - $lg->{top} < 10;
        my $line = $img->crop(top => $lg->{top}, bottom => $lg->{bottom});
        push @ret, {
            image =>  $line,
            margin => { top => $lg->{top}, bottom => $lg->{bottom} }
        };
    }
    return \@ret;
}

sub cut_text_lines_with_margin {
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

    for my $row ( 0.. $img_height - 1 ) {
        my $white_count = 0;
        for my $col (0 .. $img_width-1) {
            my $c = $img->getpixel( x => $col, y => $row );
            if ($c->equals(other => $color_white, ignore_alpha => 1)) {
                $white_count++;
            }
        }

        my $is_blank = ( $white_count == $img_width );
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

sub cut_text_rectangles {
    my $self = $_[0];

    my @ret;
    my $rowcut = $self->cut_text_lines_with_margin;
    for my $o (@$rowcut) {
        my $x = $self->new( image => $o->{image}->copy->rotate( right => 90 ) );
        my $colcut = $x->cut_text_lines_with_margin;
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

1;
