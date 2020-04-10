#! /usr/bin/perl -w
use strict;

##log.np : name *.flagstat *.coverage
die "Usage : perl $0 <logPATHlist> <outpre>\n" unless @ARGV==2;

open IN,"$ARGV[0]" or die $!;
open OUT,">$ARGV[1]" or die $!;
print OUT "NAME\tRinput\tRpis\tAllmap_p\tPPmap_p\tAllmapDeal_p\tPPmapDeal_p\t";
print OUT "Allmap_c\tPPmap_c\tAllmapDeal_c\tPPmapDeal_c\tCVG\tDepth\tmapLen\tGlen\n";
while(<IN>){
    chomp;
    next if (/^#/);
    my($name,$flagpath,$cvgpath) = (split /\s+/,$_)[0,1,2];
    my ($Rtotal,$Rpis,$Rsecd,$Rsuply,$Allmap,$AllmapC,$PPmap,$PPmapC) = (0,0,0,0,0,0,0,0);
    open FS,"$flagpath" or die $!;
    while(<FS>){
        if($_=~ /(\d+)\s\+\s\d+\sin total \(QC-passed reads \+ QC-failed reads\)/){
            $Rtotal = $1;
        }
        if($_ =~ /(\d+)\s\+\s\d+\ssecondary/){
            $Rsecd = $1;   
        }
        if($_ =~ /(\d+)\s\+\s\d+\ssupplementary/){
            $Rsuply = $1;
        }
        if($_ =~ /(\d+)\s\+\s\d+\smapped\s\((.*)\%\s\:\sN\/A\)$/){
            $AllmapC = $1;
            $Allmap = $2;
        }
        if($_ =~ /(\d+)\s\+\s\d+\spaired\sin\ssequencing$/){
            $Rpis = $1;
        }
        if($_ =~ /(\d+)\s\+\s\d+\sproperly\spaired\s\((.*)\%\s\:\sN\/A\)$/){
            $PPmapC = $1;
            #$PPmap = $2;
        }
    }
    close FS;
    my $Rinput = $Rtotal - $Rsecd - $Rsuply;
    $PPmap = sprintf("%.2f",$PPmapC/$Rinput*100);
    #$Rinput = 1500000;
    my $AllmapDealC = $AllmapC - $Rsecd - $Rsuply;
    my $AllmapDeal = sprintf("%.2f",$AllmapDealC/$Rinput*100);
    my $PPmapDeal = sprintf("%.2f",$PPmapC/$Rinput*100);
    print OUT "$name\t$Rinput\t$Rpis\t$Allmap\t$PPmap\t$AllmapDeal\t$PPmapDeal\t";
    print OUT "$AllmapC\t$PPmapC\t$AllmapDealC\t$PPmapC\t";
    ###Parse cvg_file
    my $cvg = 100;
    my $maplen = 0;
    my $gnmlen = 0;
    open CV,"$cvgpath" or die $!;
    while(<CV>){
        next unless(/^genome/);
        chomp;
        my @temp = split /\s+/,$_;
        $gnmlen = $temp[3];
        $maplen = $temp[3];
        if($temp[1] == 0 ){
            $maplen = $temp[3]-$temp[2];
            $cvg = sprintf("%.2f",(1-$temp[4])*100);
            last;
        }
    }
    my $Depth = 0;
    open Dep,"$cvgpath.percontig" or die $!;
    while(<Dep>){
        chomp;
        next unless(/^genome/);
        chomp; 
        $Depth = (split /\s+/,$_)[1];
    }
    printf OUT "$cvg\t$Depth\t$maplen\t$gnmlen\n"; 
}
close IN;
