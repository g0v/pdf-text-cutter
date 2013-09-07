package ImageCutter;
use v5.14;
use Moo;
use Imager;
use ImageTester;

has image => (
    is => "rw",
    requried => 1
);

has background => (
    is => "ro",
    default => sub { Imager::Color->new(255,255,255,0) }
);

has xymin => (
    is => "ro",
    default => 24
);

sub clean_outlier_pixels {
    my ($self) = @_;
    my $size_grid = 4;
    my $area_grid = $size_grid ** 2;
    my $img = $self->image;
    my $img_width = $img->getwidth;
    my $img_height = $img->getheight;
    my $color_white = Imager::Color->new( grey => 255 );

    for (my $x  = 0; $x < $img_width; $x += $size_grid) {
        for (my $y = 0; $y < $img_height; $y += $size_grid) {
            my $grid = $img->crop( top => $y, left => $x, width => $size_grid, height => $size_grid ) or next;
            my $color_count = $grid->getcolorusagehash;
            my @colors = sort { $color_count->{$b} <=> $color_count->{$a} } keys %$color_count;
            my $c0 = unpack("C", $colors[0]);

            if ($c0 == 255 && $color_count->{$colors[0]} < $area_grid) {
                if ($color_count->{$colors[0]} > 0.*$area_grid) {
                    $img->box(
                        xmin => $x, ymin => $y,
                        xmax => $x+$size_grid-1,
                        ymax => $y+$size_grid-1,
                        fill => { solid => $color_white },
                    );
                }
            }
        }
    }
}

# return an ArrayRef[{ image => Imager, top => Int, bottom => Int }]
sub cut_by_grid {
    my ($self) = @_;
    my $output = [];
    my $img = $self->image;

    $img = $img->convert(preset=>'grey');
    $img->write(file => "output/before.png");
    $self->image($img);

    $self->clean_outlier_pixels;

    $self->image->write(file => "output/after.png");

    my $size_grid = 6;
    my $img_width = $img->getwidth();
    my $img_height = $img->getheight();
    my $color_white = Imager::Color->new( grey => 255 );

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

    $img = $img->convert(preset=>'grey');

    # $self->image($img);
    # $self->clean_outlier_pixels;
    # $self->image->write(file => "output/after-clean-pixels.png");
    # $img = $self->image;

    my $img_width = $img->getwidth();
    my $img_height = $img->getheight();

    my $color_white = Imager::Color->new(255,0,0,0);

    # find groups of contiguous rows that are not completely white.
    my $line_group;
    my @line_groups;
    my $previous_line_is_blank = 1;

    for my $row ( 0.. $img_height - 1 ) {
        my $white_count = 0;
        for my $col (0 .. $img_width-1) {
            my $c = $img->getpixel( x => $col, y => $row );
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

1;
