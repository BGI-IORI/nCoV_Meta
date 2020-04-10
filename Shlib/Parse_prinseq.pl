#! /usr/bin/perl -w
use strict;

die "Usage : perl $0 <PE|SE> <lcr_log.np> <out_prefixe>\n" unless @ARGV==3;

open LIST,"$ARGV[1]" or die $!;
my @list = <LIST>;
chomp(@list);
close LIST;
if($ARGV[0] eq "SE"){
    open OUT,">$ARGV[2].prinseqSE.xls" or die $!;
    print OUT "Sample\tTotal\tlcr\tClean\tlcr_r\tClean_r\n";
    foreach my $list(@list){
        my($name,$log) = split /\s+/,$list;
        open LOG,"$log" or die $!;
        <LOG>;
        my $line_t = <LOG>;
        <LOG>;
        <LOG>;
        my $line_f = <LOG>;
        close LOG;
        $line_t =~ /\s+Input sequences\:\s+(.*)$/;
        my $total = $1;
        $total =~ s/\,//g;
        $line_f =~ /\s+Good sequences\:\s+(.*)\s+\(.*\)$/;
        my $clean = $1;
        $clean =~ s/\,//g;
        my $filtered = $total - $clean;
        print OUT "$name\t$total\t$filtered\t$clean\t";
        printf OUT "%.2f",$filtered/$total*100;
        print OUT "\t";
        printf OUT "%.2f",$clean/$total*100;
        print OUT "\n";
    }
    close OUT;
}elsif($ARGV[0] eq "PE"){
    open OUT,">$ARGV[2].prinseqPE.xls" or die $!;
    print OUT "Sample\tTotal\tlcr\tClean\tlcr_r\tClean_r\n";
    foreach my $list(@list){
        my($name,$log) = split /\s+/,$list;
        open LOG,"$log" or die $!;
        <LOG>;
        my $line_t = <LOG>;
        <LOG>;<LOG>;<LOG>;<LOG>;<LOG>;
        my $line_f = <LOG>;
        close LOG;
        $line_t =~ /\s+Input sequences \(file 1\)\:\s+(.*)$/;
        my $total = $1;
        $total =~ s/\,//g;
        $line_f =~ /\s+Good sequences \(pairs\)\:\s+(.*)$/;
        my $clean = $1;
        $clean =~ s/\,//g;
        my $filtered = $total - $clean;
        print OUT "$name\t$total\t$filtered\t$clean\t";
        printf OUT "%.2f",$filtered/$total*100;
        print OUT "\t";
        printf OUT "%.2f",$clean/$total*100;
        print OUT "\n";
    }
    close OUT;
}
