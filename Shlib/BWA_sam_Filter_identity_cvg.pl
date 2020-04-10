#! /usr/bin/perl -w

use FindBin qw($Bin $Script);
use Getopt::Std;
use File::Path;
use File::Spec;
our %opts = (o=>'out',m=>'0.8',s=>'0.9');
getopts('i:o:m:s:',\%opts);

die "perl $0
          -i   input sam/bam
          -o   out.sam  [$opts{'o'}]
          -m   coverage of mapped query [$opts{'m'}]
          -s   identity of matched part [$opts{'s'}]
          \n" unless (exists $opts{'i'});

$opts{'o'}  = File::Spec->rel2abs($opts{'o'});

my $FLTed = 0;
open FILE,"samtools view -h $opts{'i'}|" or die $!; 
open OUTmap,">$opts{'o'}" or die $!;
open FLT,">$opts{'o'}.FLT_list" or die $!;
while(<FILE>){
    chomp;
    if(/^@/){
        print OUTmap "$_\n";
        next;
    };
    my @temp = split /\s+/,$_;
    my ($name,$MinQ,$cigar,$seq) = @temp[0,4,5,9];
    my $MD;
    foreach my $temp(@temp){
        if($temp =~ /MD\:Z\:/){
            $MD = $temp;
            last;
        }
    }
    if($cigar eq "*"){
        print OUTmap "$_\n";
        next;
    }
    if(!defined $MD){
        print OUTmap "$_\n";
        next;
    }
    my $length = length($seq); 
    ###cvg
    my $match = &MCH($cigar);
    my $cvg = $match/$length;
    ###identity
    my $same = &IDT($MD);
    my $identity = $same/$match;
    if ($cvg >= $opts{'m'} && $identity >= $opts{'s'}){
        print OUTmap "$_\n";
    }else{
        $temp[1] = 4;
        $temp[4] = 0;
        $FLTed +=1;
        print OUTmap (join "\t",@temp),"\n";
        print FLT "$_\n";
    }
}
close OUTmap;
close FLT;
print "Filted Reads:\t$FLTed\n";

sub MCH{
    my $cigar = shift;
    my @cigar = $cigar =~ /(\d+\w)/g;
    my $match = 0;
    foreach my $m(@cigar){
        if ($m =~ /(\d+)M/){    
            $match += $1;
        }
    }
    return $match;
}
sub IDT{
    my $MD = shift; ### MD:Z:56T32A10
    $MD = (split /\:/,$MD)[2];
    $MD =~ s/[\^ATGCNatgcn]/\t/g;
    my @match = split /\t/,$MD;
    my $same = 0;
    foreach my $m (@match){
        next unless ($m =~/\d+/);
        $same += $m;
    }
    return $same;
}
