
use Imager;
use Imager::LineTrace;
 
my $img = Imager::LineTrace->new( file => $ARGV[0] ) or die Imager->errstr;
my $figures_ref = $img->line_trace();

my $i = 0;
foreach my $figure (@{$figures_ref}) {
    next if $figure->{type} eq 'Point';

    print "-------- [", $i++, "] --------", "\n";
    print "type        : ", $figure->{type}, "\n";
    print "trace_value : ", sprintf("0x%06X", $figure->{value}), "\n";
    print "is_close: ", $figure->{is_closed}, "\n";
    foreach my $p (@{$figure->{points}}) {
        printf( "(%2d,%2d)\n", $p->[0], $p->[1] );
    }
}
