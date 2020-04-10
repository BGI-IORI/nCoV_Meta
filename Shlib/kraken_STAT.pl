#! /usr/bin/perl -w
use strict;
die "usage: $0 <fqstat.np> <log.np> <out_file>\n" unless @ARGV==3;

my %fqstat1;
my %fqstat2;
open NP1,"$ARGV[0]" or die $!;
while(<NP1>){
    chomp;
    my($name,$path1,$path2) = (split /\s+/,$_)[0,1,2];
    open FS1,"$path1" or die $!;
    my $fqstat = <FS1>;
    $fqstat =~ /Num reads:(\d+)\s+Num Bases: \d+\n$/;
    $fqstat1{$name} = $1;
    close FS1;
    open FS2,"$path2" or die $!;
    my $fqstat = <FS2>;
    $fqstat =~ /Num reads:(\d+)\s+Num Bases: \d+\n$/;
    $fqstat2{$name} = $1;
    close FS2;

}
close NP1;

open NP2,"$ARGV[1]" or die $!;
open OUT,">$ARGV[2]" or die $!;
print OUT "Sample\tTotal\tUnclas_rate\tClas_rate\tUnclas\tClas\tFqSign\n";
while(<NP2>){
    chomp;
    my($name,$path) = (split /\s+/,$_)[0,1];
    open Log,"$path" or die $!;
    <Log>;
    my $cls = <Log>;
    my $ucls = <Log>;
    $cls =~ /^\s+(\d+) sequences classified \((.*)\%\)\n$/;
    my $cls_count = $1;
    my $cls_perct = $2;
    $ucls =~ /^\s+(\d+) sequences unclassified \((.*)\%\)\n$/;
    my $ucls_count = $1;
    my $ucls_perct = $2;
    my $total = $cls_count + $ucls_count;
    my $sign;
    if($cls_count == $fqstat1{$name} && $fqstat1{$name} == $fqstat2{$name}){
        $sign = "OK";
    }else{
        $sign = "ERROR";
    }
    print OUT "$name\t$total\t$ucls_perct\t$cls_perct\t$ucls_count\t$cls_count\t$sign\n";
}
close NP2;
close OUT;

