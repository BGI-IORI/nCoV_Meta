#! /usr/bin/perl -w
use strict;
die "Usage : perl $0 <pilon.vcf> <outprefix> <mindepth>\n" unless @ARGV==3;

my $maskN = 0;
my $mindepth = $ARGV[2];
open IN,"$ARGV[0]" or die $!;
open OUT,">$ARGV[1].masked.bed" or die $!;
while(<IN>){
    next if(/^#/);
    chomp;
    my @temp = split /\t/,$_;
    my $DP = (split /\;/,$temp[7])[0];
    $DP =~ s/DP\=//;
    next unless ($DP =~ /^\d+$/);
    if ($DP < $mindepth ){
        print OUT "$temp[0]|pilon\t",$temp[1]-1,"\t",$temp[1],"\n";
        $maskN += 1;
    }
}
close IN;
close OUT;

open STAT,">$ARGV[1].stat" or die $!;
print STAT "maskN\t$maskN\n";
close STAT;


