#!/usr/bin/perl

use strict;
use warnings;
use Statistics::Basic qw(:all);
my $filename = $ARGV[0];

open my $fh, '<', $filename or die "Cannot open $filename: $!";

while ( my $line = <$fh> ) {
    chomp $line;
    my $original = "/users/cn/efloden/projects/guidance-shuffle/data/bench1.0/prefab4/in/$line";
    my $new = "/users/cn/efloden/projects/guidance-shuffle/data/bench1.0/prefab4_unstable/$line";
    system( "cp $original $new");
}
close($fh);

