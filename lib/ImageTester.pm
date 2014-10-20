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

sub guess_background_color {
    my $self = $_[0];
    my $color_count = $self->image->getcolorusagehash;
    my @color = sort { $color_count->{$b} <=> $color_count->{$a} } keys %$color_count;
    return join ",", unpack("CCC", $color[0]);
}

# return: ArrayRef[Num]
sub white_score_per_row {
    my $self = shift;
    my $h = $self->image->getheight;
    my @score;
    for my $y (0..$h-1) {
        my @pixels = $self->image->getscanline( y => $y );
        my $s = 0;
        for my $px (@pixels) {
            # Each px is scored between (0, 1) (incl)
            my ($r,$g,$b) = $px->rgba;
            $s += ($r + $g +$b)/765;
            # $s += sqrt( ($r/255)**2 + ($g/255)**2 + ($b/255)**2 );
        }
        # Each row is also scored betweend (0,1) (incl)
        push @score, $s/@pixels;
    }
    return \@score;
}

1;
