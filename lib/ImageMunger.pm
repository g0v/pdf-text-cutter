package ImageMunger;
use Moo::Role;

sub cut_margin {
    my ($self) = @_;
    my $img = $self->image;
    my $img_width = $img->getwidth;
    my $img_height = $img->getheight;
    my $color_white = Imager::Color->new( grey => 255 );

    my $margin = 0.03;
    my $x_margin = $img_width * $margin;
    my $y_margin = $img_height * $margin;

    # Left Margin
    $img->box(
        xmax => $x_margin,
        color => $color_white,
        filled => 1
    );

    # Right Margin
    $img->box(
        xmin => $img_width - $x_margin,
        xmax => $img_width,
        color => $color_white,
        filled => 1
    );

    # Top Margin
    $img->box(
        ymin => 0,
        ymax => $y_margin,
        color => $color_white,
        filled => 1
    );

    # Bottom Margin
    $img->box(
        ymin => $img_height - $y_margin,
        ymax => $img_height,
        color => $color_white,
        filled => 1
    );
}

sub clean_outlier_pixels2 {
    my ($self) = @_;

    my $img = $self->image;
    my $img_width = $img->getwidth;
    my $img_height = $img->getheight;

    my $size_grid = int($img_width * 0.01);
    $size_grid = 10 if $size_grid < 10;

    my $half_grid = int($size_grid/2);

    my $color_white = Imager::Color->new( grey => 255 );

    for (my $y = $half_grid; $y < $img_height - $half_grid; $y += 1) {
        for (my $x = $half_grid; $x < $img_width - $half_grid; $x += 1) {
            my $grid = $img->crop(
                top  => $y - $half_grid,
                left => $x - $half_grid,
                width => $size_grid,
                height => $size_grid
            ) or next;

            my $color_count = $grid->getcolorusagehash;
            my @colors = keys %$color_count;

            if (@colors == 1) {
                $x += $half_grid - 1;
                next;
            }

            @colors = sort { $color_count->{$b} <=> $color_count->{$a} } @colors;

            my $anchor_pixel = $img->getpixel(x => $x, y => $y);
            my $c0 = Imager::Color->new(grey => unpack("C", $colors[0]));
            next if $c0->equals( other => $anchor_pixel, ignore_alpha => 1);

            if ($color_count->{$colors[0]} > $size_grid ** 2 * 0.95) {
                $img->setpixel(
                    x => $x,
                    y => $y,
                    color => $c0
                );
            }
        }
    }
}

sub clean_outlier_pixels {
    my ($self) = @_;
    my $size_grid = 7;
    my $area_grid = $size_grid ** 2;

    my $img = $self->image;
    my $img_width = $img->getwidth;
    my $img_height = $img->getheight;
    my $color_white = Imager::Color->new( grey => 255 );

    for (my $x  = 0; $x < $img_width; $x += int($size_grid/2)) {
        for (my $y = 0; $y < $img_height; $y += int($size_grid/2)) {
            my $grid = $img->crop( top => $y, left => $x, width => $size_grid, height => $size_grid ) or next;
            my $color_count = $grid->getcolorusagehash;
            my @colors = sort { $color_count->{$b} <=> $color_count->{$a} } keys %$color_count;
            my $c0 = unpack("C", $colors[0]);

            if ($c0 == 255 && $color_count->{$colors[0]} < $area_grid) {
                if ($color_count->{$colors[0]} > 0.9*$area_grid) {
                    $img->box(
                        xmin => $x+1, ymin => $y+1,
                        xmax => $x+$size_grid-2,
                        ymax => $y+$size_grid-2,
                        fill => { solid => $color_white },
                    );
                }
            }
        }
    }
}

# Remove cross-page black lines
sub clean_cutlines {
    my ($self) = @_;
    my $threshold = 0.6;

    my $color_white = Imager::Color->new("#FFFFFF");

    my $img = $self->image;
    for my $i (0,1) {
        if ($i) {
            $img = $img->rotate(right => 90);
        }
        my $img_width = $img->getwidth;
        my @rows = (0..$img->getheight-1);
        @rows = (0 .. @rows/4, 3*@rows/4 .. $#rows);
        for my $y (@rows) {
            my @colors = $img->getscanline(y => $y);
            my @non_white = grep { !$_->equals(other => $color_white, ignore_alpha => 1 ) } @colors;
            if (@non_white/@colors > $threshold) {
                $img->setscanline(y => $y, pixels => [map{ $color_white } @colors]);
            }
        }
    }

    $img = $img->rotate(right => 270);
    $self->image($img);
    return $self;
}


1;
