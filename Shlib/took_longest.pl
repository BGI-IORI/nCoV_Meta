#! /usr/bin/perl -w
use strict;

die "Usage : perl <ori.fa> <longest.fa>\n" unless @ARGV==2;

my %seq;
my %length;
$/ = "\>";
open FA,"$ARGV[0]" or die $!;
<FA>;
while(<FA>){
    chomp;
    my($name,$seq) = (split /\n/,$_,2)[0,1];
    $seq{$name} = $seq;
    $length{$name} = length($seq);
}
close FA;
$/ = "\n"; 

my $sign = 0;
open OUT,">$ARGV[1]" or die $!;
foreach my $name(sort {$length{$b} <=> $length{$a}} keys %length){
    last if($sign >= 1);
    print OUT ">$name\n$seq{$name}";
    $sign ++;
}
close OUT;
