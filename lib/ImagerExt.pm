package ImagerExt;
use parent 'Imager';

use strict;
use warnings;
use Statistics::Basic ":all";

# return: ArrayRef[Num]
sub white_score_per_row {
    my ($self) = shift;
    my $h = $self->getheight;
    my @score;
    for my $y (0..$h-1) {
        my @pixels = $self->getscanline( y => $y );
        my $s = 0;
        for my $px (@pixels) {
            # Each px is scored between (0, 1) (incl)
            my ($r,$g,$b) = $px->rgba;
            $s += ($r + $g +$b)/765;
            # $s += ( ($r/255)**2 + ($g/255)**2 + ($b/255)**2 );
        }
        # Each row is also scored betweend (0,1) (incl)
        push @score, $s/@pixels;
    }
    return \@score;
}

# returns ArrayRef[ Bool ]
sub splitter_rows {
    my $self = shift;
    my $white_score = $self->white_score_per_row;
    my $score_mean = mean($white_score);
    my $score_variance = stddev($white_score);
    my @splitter = (0) x $self->getheight;
    for (my $i = 0; $i < @$white_score; $i++) {
        if ( abs($white_score->[$i] - $score_mean) > 2 * $score_variance ) {
            $splitter[$i] = 1;
        }
    }
    return \@splitter;
}

sub mark_splitter_rows_as_red {
    my ($self) = @_;
    my $splitter = $self->splitter_rows;
    my @redline = ( Imager::Color->new("#FF0000") ) x $self->getwidth;
    for (my $i = 0; $i < @$splitter; $i++) {
        if ($splitter->[$i]) {
            $self->setscanline( y => $i, pixels => \@redline );
        }
    }
    return;
}

1;

