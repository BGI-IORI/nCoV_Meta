#!/ usr/bin/perl -w
use strict;

die"Usage : perl $0 <PE|SE> <fastq|fasta> <in_id_list> <output_prefix> <raw1> [<raw2>]\n" unless @ARGV >= 5;

my %id;
open ID,"$ARGV[2]" or die $!;
while(<ID>){
    chomp;
    my $id = (split /\s+/,$_)[1];
    $id =~ s/^>//;
    $id = (split /\//,$id)[0];
    $id{$id} = 1;
}
close ID;
if($ARGV[0] eq "SE"){
    if($ARGV[1] eq "fastq"){
        &get_fq($ARGV[4],"$ARGV[3].fastq","$ARGV[3].left.id",\%id);    
    }elsif($ARGV[1] eq "fasta"){
        &get_fa($ARGV[4],"$ARGV[3].fasta","$ARGV[3].left.id",\%id);
    }
}elsif($ARGV[0] eq "PE"){
    if($ARGV[1] eq "fastq"){
        &get_fq($ARGV[4],"$ARGV[3].1.fastq","$ARGV[3].left.1.id",\%id);
        &get_fq($ARGV[5],"$ARGV[3].2.fastq","$ARGV[3].left.2.id",\%id);
    }elsif($ARGV[1] eq "fasta"){
        &get_fa($ARGV[4],"$ARGV[3].1.fasta","$ARGV[3].left.1.id",\%id);
        &get_fa($ARGV[5],"$ARGV[3].2.fasta","$ARGV[3].left.1.id",\%id);
    }
}
sub get_fq{
    my ($fq,$out,$leftid,$hash) = @_;
    my %id = %$hash;
    if ($fq =~ /\.gz$/){
        open FQ,"gzip -dc $fq|" or die $!;
    }else{open FQ,"$fq" or die $!;}
    open OUT,">$out" or die $!;
    while(<FQ>){
        chomp;
        my $name = $_;
        $name =~ s/^@//;
        my $index = (split /\//,(split /\s+/,$name)[0])[0];
        my $seq = <FQ>;
        my $line3 = <FQ>; 
        my $line4 = <FQ>;
        if (exists $id{$index}){
            print OUT "\@$name\n";
            print OUT "$seq";
            print OUT "$line3";
            print OUT "$line4";
            delete $id{$index};
        }
    }
    close OUT;close FQ;
    if(%id){
        open Left,">$leftid" or die $!;
        foreach my $id(keys %id){
            print Left "$id\n";
        }
        close Left;
    }
}
sub get_fa{
    my ($fa,$out,$leftid,$hash) = @_;
    my %id = %$hash;
    if ($fa =~ /\.gz$/){
        open FA,"gzip -dc $fa|" or die $!;
    }else{open FA,"$fa" or die $!;}
    $/ = ">";
    <FA>;
    open OUT,">$out" or die $!;
    while(<FA>){
        chomp;
        my ($name,$seq) = (split /\n/,$_,2)[0,1];
        my $index = (split /\//,$name)[0];
        if (exists $id{$index}){
            print OUT "\>$name\n";
            print OUT "$seq";
            delete $id{$index};
        }
    }
    close OUT;close FA;
    if(%id){
        open Left,">$leftid" or die $!;
        foreach my $id(keys %id){
            print Left "$id\n";
        }
        close Left;
    }
}
