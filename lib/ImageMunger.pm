package ImageMunger;
use Moo::Role;

sub clean_outlier_pixels2 {
    my ($self) = @_;
    my $size_grid = 10;
    my $half_grid = int($size_grid/2);
    my $area_grid = $size_grid ** 2;

    my $img = $self->image;
    my $img_width = $img->getwidth;
    my $img_height = $img->getheight;
    my $color_white = Imager::Color->new( grey => 255 );

    for (my $x = $half_grid; $x < $img_width - $half_grid; $x += 1) {
        for (my $y = $half_grid; $y < $img_height - $half_grid; $y += 1) {
            my $anchor_pixel = $img->getpixel(x => $x, y => $y);

            my $grid = $img->crop(
                top  => $y - $half_grid,
                left => $x - $half_grid,
                width => $size_grid,
                height => $size_grid
            ) or next;

            my $color_count = $grid->getcolorusagehash;
            my @colors = sort { $color_count->{$b} <=> $color_count->{$a} } keys %$color_count;
            my $c0 = Imager::Color->new(grey => unpack("C", $colors[0]));
            next if $c0->equals( other => $anchor_pixel, ignore_alpha => 1);

            if ($color_count->{$colors[0]} > $area_grid * 0.95) {
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


1;
