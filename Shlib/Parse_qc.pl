#! /usr/bin/perl -w
use strict;

die "Usage : perl $0 <PE|SE> <qc_log.np> <out_prefixe>\n" unless @ARGV==3;

open LIST,"$ARGV[1]" or die $!;
my @list = <LIST>;
chomp(@list);
close LIST;
if($ARGV[0] eq "SE"){
    open OUT,">$ARGV[2].qcSE.xls" or die $!;
    print OUT "Sample\tTotal\tFiltered\tClean\tFiltered_r\tClean_r\n";
    foreach my $list(@list){
        my($name,$log) = split /\s+/,$list;
        open LOG,"$log" or die $!;
        <LOG>;<LOG>;
        my $line_t = <LOG>;
        my $line_f = <LOG>;
        close LOG;
        $line_t =~ /Total number of reads\s+(\d+)\s+.*/;
        my $total = $1;
        $line_f =~ /Number of filtered reads \(\%\)\s+(\d+)\s+.*/;
        my $filtered = $1;
        my $clean = $total - $filtered;
        print OUT "$name\t$total\t$filtered\t$clean\t";
        printf OUT "%.2f",$filtered/$total*100;
        print OUT "\t";
        printf OUT "%.2f",$clean/$total*100;
        print OUT "\n";
    }
    close OUT;
}elsif($ARGV[0] eq "PE"){
    open OUT,">$ARGV[2].soapnukePE.xls" or die $!;
    print OUT "Sample\tTotal\tFiltered\tClean\tFiltered_r\tClean_r\tFLTadpt\tFLTlq\tFLTlmq\tFLTdup\tFLTn\tFLTsis\tFLTpla\n";
    foreach my $list(@list){
        my($name,$log) = split /\s+/,$list;
        open LOG,"$log" or die $!;
        <LOG>;<LOG>;
        my $line_t = <LOG>;
        my $line_f = <LOG>;
        close LOG;
        $line_t =~ /Total number of reads\s+(\d+)\s+.*/;
        my $total = $1;
        $line_f =~ /Number of filtered reads \(\%\)\s+(\d+)\s+.*/;
        my $filtered = $1;
        my $clean = $total - $filtered;
        print OUT "$name\t$total\t$filtered\t$clean\t";
        printf OUT "%.2f",$filtered/$total*100;
        print OUT "\t";
        printf OUT "%.2f",$clean/$total*100;
        print OUT "\t";
        ####################################
        $log =~ s/Basic_Statistics_of_Sequencing_Quality.txt/Statistics_of_Filtered_Reads.txt/;
        open LOG2,"$log" or die $!;
        while(<LOG2>){
            #if($_ =~ /Total filtered reads \(\%\)\s+\d+\s+(.*)\%\s+\d+\s+.*\%\s+\d+\s+.*\%$/){print OUT "$1\t";}
            if($_ =~ /Reads with adapter \(\%\)\s+\d+\s+(.*)\%\s+\d+\s+.*\%\s+\d+\s+.*\%$/){print OUT "$1\t";}
            if($_ =~ /Reads with low quality \(\%\)\s+\d+\s+(.*)\%\s+\d+\s+.*\%\s+\d+\s+.*\%$/){print OUT "$1\t";}
            if($_ =~ /Reads with low mean quality \(\%\)\s+\d+\s+(.*)\%\s+\d+\s+.*\%\s+\d+\s+.*\%$/){print OUT "$1\t";}
            if($_ =~ /Reads with duplications \(\%\)\s+\d+\s+(.*)\%\s+\d+\s+.*\%\s+\d+\s+.*\%$/){print OUT "$1\t";}
            if($_ =~ /Read with n rate exceed\: \(\%\)\s+\d+\s+(.*)\%\s+\d+\s+.*\%\s+\d+\s+.*\%$/){print OUT "$1\t";}
            if($_ =~ /Read with small insert size\: \(\%\)\s+\d+\s+(.*)\%\s+\d+\s+.*\%\s+\d+\s+.*\%$/){print OUT "$1\t";}
            if($_ =~ /Reads with PolyA \(\%\)\s+\d+\s+(.*)\%\s+\d+\s+.*\%\s+\d+\s+.*\%$/){print OUT "$1\n";}
        }
    }
    close OUT;
}
