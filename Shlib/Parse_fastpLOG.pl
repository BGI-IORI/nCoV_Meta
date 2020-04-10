#! /usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Spec;
use FindBin qw($Bin);

die "Usage : perl $0 <PE|SE> <fastp_log.np> <out_prefixe>\n" unless @ARGV==3;

if($ARGV[0] eq "SE"){
    open LIST,"$ARGV[1]" or die $!;
    open OUT,">$ARGV[2].fastpSE.xls" or die $!;
    print OUT "Sample\tTotal\tFiltered\tClean\tFiltered_r\tClean_r\tDup_r\tAdapt_r\tFLTlq\tFLTn\tFLTs\n";
    while(<LIST>){
        chomp;
        my($name,$path) = (split /\s+/,$_)[0,1];
        my ($input,$output,$FLTlq,$FLTn,$FLTs,$Adapt,$Dup_r) = (0,0,0,0,0,0,0);
        open IN,"$path" or die $!;
        while(<IN>){
            chomp;
            if($_ =~ /^total reads:\s+(\d+)$/ && $input == 0){
                $input = $1;next;
            }
            if($_ =~ /^total reads:\s+(\d+)$/ && $output == 0){
                $output = $1;next;
            }
            if($_ =~ /^reads failed due to low quality:\s+(\d+)$/){
                $FLTlq = $1;next;
            }
            if($_ =~ /^reads failed due to too many N:\s+(\d+)$/){
                $FLTn = $1;next;
            }
            if($_ =~ /^reads failed due to too short:\s+(\d+)$/){
                $FLTs = $1;next;
            }
            if($_ =~ /^reads with adapter trimmed:\s+(\d+)$/){
                $Adapt = $1;next;
            }
            if($_ =~ /^Duplication rate:\s+(.*)\%$/){
                $Dup_r = $1;
            }
        }
        close IN;
        my $Filtered = $input - $output;
        my $Filtered_r = sprintf "%.2f",$Filtered/$input*100;
        my $Clean_r = sprintf "%.2f",$output/$input*100;
        my $FLTlq_r = sprintf "%.2f",$FLTlq/$Filtered*100;
        my $FLTn_r = sprintf "%.2f",$FLTn/$Filtered*100;
        my $FLTs_r = sprintf "%.2f",$FLTs/$Filtered*100;
        my $Adapt_r = sprintf "%.2f",$Adapt/$input*100;
        print OUT "$name\t$input\t$Filtered\t$output\t$Filtered_r\t$Clean_r\t$Dup_r\t$Adapt_r\t$FLTlq_r\t$FLTn_r\t$FLTs_r\n";
    }
    close LIST;
    close OUT;
}elsif($ARGV[0] eq "PE"){
    open LIST,"$ARGV[1]" or die $!;
    open OUT,">$ARGV[2].fastpPE.xls" or die $!;
    print OUT "Sample\tTotal\tFiltered\tClean\tFiltered_r\tClean_r\tDup_r\tAdapt_r\tFLTlq\tFLTn\tFLTs\n";
    while(<LIST>){
        chomp;
        my($name,$path) = (split /\s+/,$_)[0,1];
        my ($input,$output,$FLTlq,$FLTn,$FLTs,$Adapt,$Dup_r) = (0,0,0,0,0,0,0);
        open IN,"$path" or die $!; 
        while(<IN>){
            chomp;
            if($_ =~ /^total reads:\s+(\d+)$/ && $input == 0){
                $input = $1;next;
            }
            if($_ =~ /^total reads:\s+(\d+)$/ && $output == 0){
                $output = $1;next;
            }
            if($_ =~ /^reads failed due to low quality:\s+(\d+)$/){
                $FLTlq = $1/2;next;
            }
            if($_ =~ /^reads failed due to too many N:\s+(\d+)$/){
                $FLTn = $1/2;next;
            }
            if($_ =~ /^reads failed due to too short:\s+(\d+)$/){
                $FLTs = $1/2;next;
            }
            if($_ =~ /^reads with adapter trimmed:\s+(\d+)$/){
                $Adapt = $1/2;next;
            }
            if($_ =~ /^Duplication rate:\s+(.*)\%$/){
                $Dup_r = $1;
            }
        }
        close IN;
        my $Filtered = $input - $output;
        my $Filtered_r = sprintf "%.2f",$Filtered/$input*100;
        my $Clean_r = sprintf "%.2f",$output/$input*100;
        my $FLTlq_r = sprintf "%.2f",$FLTlq/$Filtered*100;
        my $FLTn_r = sprintf "%.2f",$FLTn/$Filtered*100;
        my $FLTs_r = sprintf "%.2f",$FLTs/$Filtered*100;
        my $Adapt_r = sprintf "%.2f",$Adapt/$input*100;
        print OUT "$name\t$input\t$Filtered\t$output\t$Filtered_r\t$Clean_r\t$Dup_r\t$Adapt_r\t$FLTlq_r\t$FLTn_r\t$FLTs_r\n";
    }
    close OUT;
    close LIST;
}
