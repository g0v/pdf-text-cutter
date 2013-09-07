package ImageTester;
use Moo;
use Imager;
use Imager::Color;

has image => (
    is => "ro",
    requried => 1
);

sub color_background {
    return Imager::Color->new( grey => 255 );
}

sub contains_only_background {
    my $self = $_[0];
    my $img = $self->image;
    my $color_background = $self->color_background;
    for my $x (0 .. $img->getwidth-1) {
        for my $y (0 .. $img->getheight-1) {
            my $pixel = $img->getpixel( x => $x, y => $y);
            unless($pixel->equals( other => $color_background, ignore_alpha => 1)) {
                return 0;
            }
        }
    }
    return 1;
}

sub bottom_edge_contains_only_background {
    my $self = $_[0];
    my $img = $self->image;

    my $edge = $img->getheight-1;
    my $color_background = $self->color_background;
    for my $x (0 .. $img->getwidth-1) {
        my $pixel = $img->getpixel( x => $x, y => $edge );
        unless($pixel->equals( other => $color_background, ignore_alpha => 1)) {
            return 0;
        }
    }
    return 1;
}

sub remove_outlier_pixels {
    my $self = $_[0];
    my $img = $self->image;

    my $img_width = $img->getwidth();
    my $img_height = $img->getheight();
    my $color_background = Imager::Color->new(255,255,255,0);

    my %freq;
    for my $x ( 0 .. $img_width-1 ) {
        for my $y ( 0 .. $img_height-1 ) {
            my $px = $img->getpixel( x => $x, y => $y);
            my $color = join ",", $px->rgba;
            $freq{$color} += 1;
        }
    }

    return $img;
}

sub guess_background_color {
    my $self = $_[0];
    my $color_count = $self->image->getcolorusagehash;
    my @color = sort { $color_count->{$b} <=> $color_count->{$a} } keys %$color_count;
    return unpack("C", $color[0]);
}

1;
