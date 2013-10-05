package ImagerExt;
use v5.14;
use parent 'Imager';

use strict;
use warnings;
use Statistics::Basic ":all";

sub copy   { bless shift->SUPER::copy(@_),   __PACKAGE__ }
sub crop   {
    my $x = shift->SUPER::crop(@_);
    bless($x, __PACKAGE__) if $x;
    return $x;
}
sub rotate { bless shift->SUPER::rotate(@_), __PACKAGE__ }

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
            # $s += sqrt( ($r/255)**2 + ($g/255)**2 + ($b/255)**2 );
        }
        # Each row is also scored betweend (0,1) (incl)
        push @score, $s/@pixels;
    }
    return \@score;
}

# returns ArrayRef[ Bool ]
sub splitter_rows {
    my $self = shift;
    return $self->splitter_rows_found_with_mean_and_stddev_in_top_bucket;
}

sub splitter_rows_found_with_nn {
    my $self = shift;
    my $white_score = $self->white_score_per_row;
    my @ws = sort { $b->{score} <=> $a->{score} } map {+{ row => $_, score => $white_score->[$_] }} 0..$#$white_score;
    my @splitter = (0) x $self->getheight;
    $splitter[0] = 1;
    for my $i (1..$#ws-1) {
        my $d1 = $ws[0]->{score} - $ws[$i]->{score};
        my $d2 = $ws[$i]->{score} - $ws[$i-1]->{score};
        last if $d1 > $d2;

        $splitter[ $ws[$i]->{row} ] = 1;
    }
    return \@splitter;
}

sub splitter_rows_found_with_top_white_scores {
    my $self = shift;
    my $white_score = $self->white_score_per_row;
    my @ws = sort { $b->{score} <=> $a->{score} } map {+{ row => $_, score => $white_score->[$_] }} 0..$#$white_score;
    my @splitter = (0) x $self->getheight;

    my @top = @ws[ 0 .. @ws*0.25 ];
    for (@top) {
        $splitter[ $_->{row} ] = 1;
    }
    return \@splitter;
}

sub splitter_rows_found_with_mean_and_stddev {
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

sub splitter_rows_found_with_mean_and_stddev_in_top_bucket {
    my $self = shift;
    my $white_score = $self->white_score_per_row;
    my @ws = sort { $b->{score} <=> $a->{score} } map {+{ row => $_, score => $white_score->[$_] }} 0..$#$white_score;
    my @top_range = 0 .. 0.45*@ws;
    my @top = @ws[ @top_range ];
    my @top_score = map { $_->{score} } @top;
    my $top_mean = mean(@top_score);
    my $top_stddev = stddev(@top_score);

    my @splitter = (0) x $self->getheight;
    for (my $i = 0; $i < @top_range; $i++) {
        $splitter[ $ws[$i]->{row} ] = 1;
    }

    for (my $i = @top_range; $i < @ws; $i++) {
        if ( abs($ws[$i]->{score} - $top_mean) < $top_stddev ) {
            $splitter[ $ws[$i]->{row} ] = 1;
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

sub text_row_groups {
    my ($self, $split_method) = @_;

    my $splitters;
    if ($split_method) {
        my $method = "splitter_rows_found_with_" . $split_method;
        $splitters = $self->$method;
    }
    else {
        $splitters = $self->splitter_rows;
    }

    my $i;
    my @row_groups;
    my $group = [undef,undef,undef];
    for ($i = 0; $i < @$splitters; $i++) {
        $group->[0] //= $i;
        if (defined($group->[2])) {
            if ($group->[2] != $splitters->[$i]) {
                $group->[1] = $i;
                push @row_groups, $group;
                $group = [undef, undef, undef];
            }
        }
        else {
            $group->[2] = $splitters->[$i];
        }
    }

    return \@row_groups;
}

sub find_text_bbox {
    my $self = shift;

    my $got_a_row = sub {
        my ($top, $bottom, $left, $right) = @_;
        state $r = 0;
        my $x = $self->crop( top => $top, bottom => $bottom, left => $left, right => $right );
        say "$top - $bottom - $left - $right";
        $x->write( file => "/tmp/row/${left}-${r}.png");
        $r++;
    };

    my $color_white = Imager::Color->new("#FFFFFF");

    my $width = $self->getwidth;
    my $minwidth = $self->getwidth / 10;
    my $height = $self->getheight;

    for my $x (map { $width * $_ } 0, 0.25, 0.5, 0.75 ) {
        my $row_mode = "bg"; # bg, fg
        my $row_start;

        for (my $y = 0; $y < $height; $y++) {
            my $_width = 0.25 * $width;

            my @px = $self->getscanline(x => $x, y => $y, width => $_width);
            my %colors;
            for (@px) {
                my ($r,$g,$b) = $_->rgba;
                $colors{"$r;$g;$b"}++;
            }

            if ( @px == ($colors{"255;255;255"}||=0) ) {
                if ($row_mode eq "fg") {
                    if ($y - $row_start > 8) {
                        $got_a_row->($row_start, $y, $x, $x + $_width);
                        $row_start = undef;
                    }
                }
                else {
                    $row_start = $y;
                }
                $row_mode = "bg";
            }
            else {
                if ($row_mode eq "bg") {
                    $row_start = $y;
                }
                $row_mode = "fg";
            }
        }
    }
}


1;

