#! /usr/bin/perl -w
use strict;
die "Usage : perl $0 <cs_log.np> <out_file>\n" unless @ARGV==2;

open LIST,"$ARGV[0]" or die $!;
open OUT,">$ARGV[1]" or die $!;
print OUT "Sample\tT_num\tT_len\tT_gap\tAvg_len\tN50_len\tN90_len\tMax_len\tMin_len\tGC\tACGT\tcvg\tSign\n";
while(<LIST>){
    chomp;
    next if (/^#/);
    my($name,$log) = split /\s+/,$_;
    print OUT "$name";
    my ($total,$gap) = (0,0);
    open LOG,"$log" or die $!;
    while(<LOG>){
        chomp;
        if(/Total Number \(#\)\:\s+(\d+)\s+\d+$/){
            print OUT "\t$1";
        }
        if(/Total length \(bp\)\:\s+(\d+)\s+\d+$/){
            print OUT "\t$1";
            $total = $1;
        }
        if(/Gap\(N\)\(bp\)\:\s+(\d+)\s+\d+$/){
            print OUT "\t$1";
            $gap = $1;
        }
        if(/Average Length \(bp\)\:\s+(\S+)\s+(\S+)$/){
            print OUT "\t$1"; 
        }
        if(/N50 Length \(bp\)\:\s+(\d+)\s+\d+$/){
            print OUT "\t$1";
        }
        if(/N90 Length \(bp\)\:\s+(\d+)\s+\d+$/){
            print OUT "\t$1";
        }
        if(/Maximum Length \(bp\)\:\s+(\d+)\s+\d+$/){ 
            print OUT "\t$1";
        }
        if(/Minimum Length \(bp\)\:\s+(\d+)\s+\d+$/){
            print OUT "\t$1"; 
        }
        if(/GC content \:\s+(\S+)\s+(\S+)$/){
            print OUT "\t$1";
        }
    }
    my $ACGT = $total - $gap;
    my $cvg = sprintf ("%.2f",$ACGT/$total*100);
    my $sign = "NA";
    if ($cvg >=99){
        $sign = "100cvg";
    }elsif($cvg >=90){
        $sign = "90+cvg";
    }else{
        $sign = "90-cvg";
    }
    print OUT "\t$ACGT\t$cvg\t$sign\n"; 
    close LOG;
}
close OUT;
close LIST;
