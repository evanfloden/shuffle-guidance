#!/usr/bin/perl

use strict;
use warnings;
use Statistics::Basic qw(:all);


my $filename = $ARGV[0];

open my $fh, '<', $filename or die "Cannot open $filename: $!";

while ( my $line = <$fh> ) {
    chomp $line;
    print "$line\t";
    ### Default HoT/Guidance Scores
    #
    my $defaultResultF = "/users/cn/efloden/projects/guidance-shuffle/results_hot_unstable/$line/default_HoT_alignments/scores/MSA.MAFFT.Guidance_msa.scr";
    open my $fh3, '<', $defaultResultF or die "Cannot open $defaultResultF: $!";
      
    while ( my $line3 = <$fh3> ) {

        chomp $line3;
        if ($line3 =~ /#MEAN_RES_PAIR_SCORE (\d.\d+)  #MEAN_COL_SCORE (\d.\d+)/ )
        {
           print "$1\t"; 
           print "$2\t";
        }
    }
    close ($fh3);


    ### Shuffles HoT Guidance Score
    my $j=0;
    my @total_rp=();
    my @total_col=();

    for my $i (1..100){

        my $skip=0;
        my $shuffledResultF = "/users/cn/efloden/projects/guidance-shuffle/results_hot_unstable/${line}/shuffled_HoT_alignments/${line}_${i}/scores/MSA.MAFFT.Guidance_msa.scr";
 
         open my $fh2, '<', $shuffledResultF or $skip=1;
         if ( $skip == 0 ) {
         while ( my $line2 = <$fh2> ) {
             chomp $line2;
             if ($line2 =~ /#MEAN_RES_PAIR_SCORE (\d.\d+)  #MEAN_COL_SCORE (\d.\d+)/ ) 
             {
                 $j++;
                 push @total_rp, $1;
                 push @total_col, $2;

             } 
        }
        close ($fh2);
        }
    }

    if ($j == 100) { 

        my $mean_rp  = sprintf("%.6f", mean(@total_rp));
        my $mean_col = sprintf("%.6f", mean(@total_col)); 
        my $std_rp  = sprintf("%.6f", stddev(@total_rp));
        my $std_col = sprintf("%.6f", stddev(@total_col));
        print "$mean_rp ± $std_rp\t$mean_col ± $std_col\n";
    }
    else { print "NA\tNA\t$j\n"; }
}

close($fh);

