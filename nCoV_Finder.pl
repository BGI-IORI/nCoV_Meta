#! /usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Spec;
use POSIX qw(strftime);
use FindBin qw($Bin);
use File::Path;

my $usage=" NOTE: Pipeline for analyzing nCoV genome
    Usage:
    Options:
        -i <input>   input txt_file contain 3 col (name raw.1.fq.gz raw.2.fq.gz)
        -c <config>  configure file
        -o <opath>   output path [./result]
        -h|?Help!
    Example:perl $0 -i data.np -c test.cfg
";
my ($input,$cfg,$outpath,$help);
GetOptions(
    '-i=s' => \$input,
    '-c=s' => \$cfg,
    '-o=s' => \$outpath,
    'h|?'  => \$help,
);

if($help or !$input){die "$usage\n";}
$outpath ||= "./result";
mkdir("$outpath") unless (-d $outpath);
$outpath = File::Spec->rel2abs($outpath);
my $shellall = "$outpath/shellall";
mkdir($shellall) unless (-d $shellall );
#############################read config file
print strftime(">>>Generate shell scripts started at:%Y-%m-%d,%H:%M:%S\n\n",localtime(time));
my %config = &readConf($cfg);
my @dependent;
#############################read the input data list
my %data;
my $dataNum;
my %sample;
my @sample;
open LIST,"$input" or die $!;
open NP,">$outpath/input.np" or die $!;
while(<LIST>){
    chomp;
    next if (/^#/);
    my($name,$path1,$path2) = (split /\s+/,$_)[0,1,2];
    $path1 = File::Spec->rel2abs($path1);
    $path2 = File::Spec->rel2abs($path2);
    $data{$name} = "$path1 $path2";
    print NP "$name\t$path1\t$path2\n";
    push @sample,$name;
    $dataNum ++; 
}
close LIST;

################################### 01.Kmer based Classification
if($config{'Kmer_method'} eq "kraken"){
    my $OOO = "$outpath/01.KRAKEN";
    mkdir($OOO) unless (-d $OOO);
    open SALL,">$shellall/01.KRAKEN_dependence.txt" or die $!;
    push @dependent,"$shellall/01.KRAKEN_dependence.txt";
    open CNP,">$OOO/Odata.C.np" or die $!; 
    open QNP,">$OOO/Odata.C.fqstat.np" or die $!; 
    open LNP,">$OOO/log.np" or die $!;
    foreach my $name (@sample){
        mkpath("$OOO/$name/") unless (-d "$OOO/$name/");
        open SH1,">$OOO/$name/kraken_$name.sh" or die $!;
        print SH1 "$config{'kraken'}/kraken $config{'kraken_Parameters'} --db $config{'krakenDB'} --output $OOO/$name/$name.out.C $data{$name} 1>$OOO/$name/$name.log.o 2>$OOO/$name/$name.log.e && ";
        print SH1 "$config{'perl'} $Bin/Shlib/took_reads_byID.pl PE fastq $OOO/$name/$name.out.C $OOO/$name/$name.out.C $data{$name} && ";
        print SH1 "$Bin/Shlib/kseq_fastq_base $OOO/$name/$name.out.C.1.fastq 1>$OOO/$name/$name.out.C.1.fastq.stat && ";
        print SH1 "$Bin/Shlib/kseq_fastq_base $OOO/$name/$name.out.C.2.fastq 1>$OOO/$name/$name.out.C.2.fastq.stat && ";
        print SH1 "echo ==========01.KRAKEN end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/$name/kraken_$name.sh.sign\n";
        close SH1;
        $data{$name} = "$OOO/$name/$name.out.C.1.fastq $OOO/$name/$name.out.C.2.fastq";
        print CNP "$name\t$OOO/$name/$name.out.C.1.fastq $OOO/$name/$name.out.C.2.fastq\n";
        print QNP "$name\t$OOO/$name/$name.out.C.1.fastq.stat $OOO/$name/$name.out.C.2.fastq.stat\n";
        print LNP "$name\t$OOO/$name/$name.log.e\n";
        print SALL "sh $OOO/$name/kraken_$name.sh\n";
        print SALL "sh $OOO/stat.sh\n";
    }
    close CNP;
    close QNP;
    close LNP;
    close SALL;
    ###summary stat 
    my $kraken_STAT = "$Bin/Shlib/Parse_kraken_log.pl"; 
    open Stat,">$OOO/stat.sh" or die $!;
    print Stat "$config{'perl'} $kraken_STAT $OOO/Odata.C.fqstat.np $OOO/log.np $OOO/all_classify_kraken.xls && \\\n";
    print Stat "echo ==========01.KRAKEN_stat end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/stat.sh.sign\n";
    close Stat;
}

################################### 02.Quality control
if($config{'qcl_method'} eq "soapnuke"){
    my $OOO = "$outpath/02.QCL";
    mkdir($OOO) unless (-d $OOO);
    open SALL,">$shellall/02.QCL_dependence.txt" or die $!;
    push @dependent,"$shellall/02.QCL_dependence.txt";
    open NP,">$OOO/Odata.np" or die $!;
    open LG,">$OOO/log.fastp.np" or die $!;
    open LG1,">$OOO/log.np" or die $!;
    foreach my $name (@sample){
        mkdir("$OOO/$name") unless (-d "$OOO/$name");
        my ($path1,$path2) = (split /\s+/,$data{$name})[0,1];
        open SH1,">$OOO/$name/soapnuke_$name.sh" or die $!;
        print SH1 "$config{'fastp'} $config{'fastp_Parameters'} -i $path1 -I $path2 -o $OOO/$name/clean1.fastp.fq.gz -O $OOO/$name/clean2.fastp.fq.gz -j $OOO/$name/$name.fastp.json -h $OOO/$name/$name.fastp.html -R \"$name fastp report\" 1>$OOO/$name/$name.fastp.o 2>$OOO/$name/$name.fastp.e && \\\n";
        print SH1 "$config{'soapnuke'} $config{'soapnuke_Parameters'} -1 $OOO/$name/clean1.fastp.fq.gz -2 $OOO/$name/clean2.fastp.fq.gz -C clean1.fq.gz -D clean2.fq.gz -o $OOO/$name/ 1>$OOO/$name/$name.soapnuke.log 2>&1 && \\\n";
        print SH1 "gunzip $OOO/$name/clean1.fq.gz && gunzip $OOO/$name/clean2.fq.gz && \\\n";
        print SH1 "echo ==========02.QCL end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/$name/soapnuke_$name.sh.sign\n";
        close SH1;
        $data{$name} = "$OOO/$name/clean1.fq $OOO/$name/clean2.fq";
        print NP "$name\t$OOO/$name/clean1.fq $OOO/$name/clean2.fq\n";
        print LG "$name\t$OOO/$name/$name.fastp.e\n";
        print LG1 "$name\t$OOO/$name/Basic_Statistics_of_Sequencing_Quality.txt\n";
        print SALL "sh $OOO/$name/soapnuke_$name.sh\n";
        print SALL "sh $OOO/stat.sh\n";
    }
    close LG;
    close LG1;
    close NP;
    close SALL;
    my $Parse_fastp = "$Bin/Shlib/Parse_fastpLOG.pl PE ";
    my $Parse_soapnuke = "$Bin/Shlib/Parse_qc.pl PE ";
    open Stat, ">$OOO/stat.sh" or die $!;
    print Stat "$config{'perl'} $Parse_fastp $OOO/log.fastp.np $OOO/all_qc && \\\n";
    print Stat "$config{'perl'} $Parse_soapnuke $OOO/log.np $OOO/all_qc\n";
    print Stat "echo ==========02.QCL_stat end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/stat.sh.sign\n";
    close Stat;
}

################################### 03.Low complexity reads removing
if($config{'lcr_method'} eq "prinseq"){
    my $OOO = "$outpath/03.LCR";
    mkdir($OOO) unless (-d $OOO);
    open SALL,">$shellall/03.LCR_dependence.txt" or die $!;
    push @dependent,"$shellall/03.LCR_dependence.txt";
    open NP,">$OOO/Odata.np" or die $!;
    open LG1,">$OOO/prinseq_log.np" or die $!;
    foreach my $name (@sample){
        mkdir("$OOO/$name") unless (-d "$OOO/$name");
        my ($path1,$path2) = (split /\s+/,$data{$name})[0,1];
        open SH1,">$OOO/$name/prinseq_$name.sh" or die $!;
        print SH1 "$config{'perl'} $config{'prinseq'} $config{'prinseq_Parameters'} -fastq $path1 -fastq2 $path2 -out_good $OOO/$name/$name.good -out_bad $OOO/$name/$name.bad 2>$OOO/$name/$name.prinseq.log && \\\n";
        print SH1 "echo ==========03.LCR end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/$name/prinseq_$name.sh.sign\n";
        close SH1;
        $data{$name} = "$OOO/$name/$name.good_1.fastq $OOO/$name/$name.good_2.fastq $OOO/$name/$name.good_12_singletons.fastq";
        print NP "$name\t$OOO/$name/$name.good_1.fastq $OOO/$name/$name.good_2.fastq $OOO/$name/$name.good_12_singletons.fastq \n";
        print LG1 "$name\t$OOO/$name/$name.prinseq.log\n";
        print SALL "sh $OOO/$name/prinseq_$name.sh\n";
        print SALL "sh $OOO/stat.sh\n";
    }
    close LG1;
    close NP;
    close SALL;
    my $Parse_prinseq = "$Bin/Shlib/Parse_prinseq.pl";
    open Stat, ">$OOO/stat.sh" or die $!;
    print Stat "$config{'perl'} $Parse_prinseq PE $OOO/prinseq_log.np $OOO/all_lcr\n";
    print Stat "echo ==========03.LCR_stat end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/stat.sh.sign\n";
    close Stat;
}

################################### 04.Coverage evaluation
if($config{'cvg_method'} eq "bwa"){
    my $OOO = "$outpath/04.CVG";
    mkdir($OOO) unless (-d $OOO);
    open SALL,">$shellall/04.CVG_dependence.txt" or die $!;
    push @dependent,"$shellall/04.CVG_dependence.txt";
    open NP,">$OOO/Odata.np" or die $!;
    open LG1,">$OOO/log.np" or die $!;
    foreach my $name (@sample){
        mkdir("$OOO/$name") unless (-d "$OOO/$name");
        my ($path1,$path2) = (split /\s+/,$data{$name})[0,1];
        open SH1,">$OOO/$name/cvg_$name.sh" or die $!;
        print SH1 "$config{'bwa'} $config{'bwa_Parameters'} $config{'bwa_DB'} $path1 > $OOO/$name/Ref_nCoV_$name.1.sai 2>$OOO/$name/Ref_nCoV_$name.1.sai.log && \\\n";
        print SH1 "$config{'bwa'} $config{'bwa_Parameters'} $config{'bwa_DB'} $path2 > $OOO/$name/Ref_nCoV_$name.2.sai 2>$OOO/$name/Ref_nCoV_$name.2.sai.log && \\\n";
        print SH1 "$config{'bwa'} sampe $config{'bwa_DB'} $OOO/$name/Ref_nCoV_$name.1.sai $OOO/$name/Ref_nCoV_$name.2.sai $path1 $path2 >$OOO/$name/Ref_nCoV_$name.ori.sam 2>$OOO/$name/Ref_nCoV_$name.ori.sam.log && \\\n";
        print SH1 "$config{'perl'} $Bin/Shlib/BWA_sam_Filter_identity_cvg.pl -i $OOO/$name/Ref_nCoV_$name.ori.sam -o $OOO/$name/Ref_nCoV_$name.sam -m 0.95 -s 0.90 1>$OOO/$name/Ref_nCoV_$name.ori.sam.FLT.log 2>&1 && \\\n";
        print SH1 "$config{'samtools'} view -bt $config{'bwa_DB'}.fai $OOO/$name/Ref_nCoV_$name.sam > $OOO/$name/Ref_nCoV_${name}-uF.bam && \\\n";
        print SH1 "$config{'samtools'} sort -n $OOO/$name/Ref_nCoV_${name}-uF.bam|$config{'samtools'} fixmate - $OOO/$name/Ref_nCoV_$name.bam && \\\n";
        print SH1 "$config{'samtools'} flagstat $OOO/$name/Ref_nCoV_$name.bam > $OOO/$name/Ref_nCoV_$name.bam.flagstat && \\\n";
        print SH1 "$config{'samtools'} sort $OOO/$name/Ref_nCoV_$name.bam -o $OOO/$name/Ref_nCoV_${name}-s.bam --reference $config{'bwa_DB'} && \\\n";
        print SH1 "$config{'samtools'} index $OOO/$name/Ref_nCoV_${name}-s.bam && \\\n";
        print SH1 "$config{'java'} -jar $config{'picard'} $config{'picard_Parameters'} INPUT=$OOO/$name/Ref_nCoV_${name}-s.bam OUTPUT=$OOO/$name/Ref_nCoV_${name}-smd.bam METRICS_FILE=$OOO/$name/Ref_nCoV_${name}-smd.metrics >$OOO/$name/Ref_nCoV_${name}-smd.bam.log 2>&1 && \\\n";
        print SH1 "$config{'samtools'} sort $OOO/$name/Ref_nCoV_${name}-smd.bam -o $OOO/$name/Ref_nCoV_${name}-smds.bam --reference $config{'bwa_DB'} && \\\n";
        print SH1 "$config{'samtools'} index $OOO/$name/Ref_nCoV_${name}-smds.bam && \\\n";
        print SH1 "$config{'bedtools'} genomecov -ibam $OOO/$name/Ref_nCoV_${name}-smds.bam >$OOO/$name/Ref_nCoV_${name}-smds.bam.coverage && \\\n";
        print SH1 "awk \'BEGIN {pc=\"\"} {c=\$1;if (c == pc) {cov=cov+\$2*\$5;} else {print pc,cov;cov=\$2*\$5;pc=c}} END {print pc,cov}' $OOO/$name/Ref_nCoV_${name}-smds.bam.coverage| tail -n +2 > $OOO/$name/Ref_nCoV_${name}-smds.bam.coverage.percontig && \\\n";
        print SH1 "$config{'samtools'} sort -n $OOO/$name/Ref_nCoV_${name}-smds.bam|$config{'samtools'} fastq -F 12 -1 $OOO/$name/Ref_nCoV_${name}-smds.bam.1.fq -2 $OOO/$name/Ref_nCoV_${name}-smds.bam.2.fq - >$OOO/$name/Ref_nCoV_${name}-smds.bam.fqlog 2>&1 && \\\n";
        print SH1 "echo ==========04.CVG end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/$name/cvg_$name.sh.sign\n";
        close SH1;
        $data{"$name.bam"} = "$OOO/$name/Ref_nCoV_$name-smds.bam";
        $data{"$name.bamfq"} = "$OOO/$name/Ref_nCoV_${name}-smds.bam.1.fq\t$OOO/$name/Ref_nCoV_${name}-smds.bam.2.fq";
        print LG1 "$name\t$OOO/$name/Ref_nCoV_$name.bam.flagstat\t$OOO/$name/Ref_nCoV_${name}-smds.bam.coverage\n";
        print SALL "sh $OOO/$name/cvg_$name.sh\n";
        print SALL "sh $OOO/stat.sh\n";
    }
    close LG1;
    close NP;
    my $Parse_cvg = "$Bin/Shlib/Mapping_cvg_stat.pl";
    open Stat, ">$OOO/stat.sh" or die $!;
    print Stat "$config{'perl'} $Parse_cvg $OOO/log.np $OOO/all_cvg.xls\n";
    print Stat "echo ==========04.CVG_stat end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/stat.sh.sign\n";
    close Stat;
    close SALL;
}

################################### 05.Assemble contigs
if($config{'ass_method'} eq "spades"){
    my $OOO = "$outpath/05.ASS";
    mkdir($OOO) unless (-d $OOO);
    open SALL,">$shellall/05.ASS_dependence.txt" or die $!;
    push @dependent,"$shellall/05.ASS_dependence.txt";
    open NP,">$OOO/Odata.np" or die $!;
    open NP2,">$OOO/Odata_longest.np" or die $!;
    open LG1,">$OOO/log.np" or die $!;
    foreach my $name (@sample){
        mkdir("$OOO/$name") unless (-d "$OOO/$name");
        my ($path1,$path2) = (split /\s+/,$data{$name})[0,1];
        open SH1,">$OOO/$name/spades_$name.sh" or die $!;
        #If there are too much data, you can choose to subsample some data 
        #print SH1 "head -60000 $path1 > $OOO/$name/data.100X.1.fastq && \\\n";
        #print SH1 "head -60000 $path2 > $OOO/$name/data.100X.2.fastq && \\\n";
        #$path1 = "$OOO/$name/data.100X.1.fastq";
        #$path2 = "$OOO/$name/data.100X.2.fastq";
        print SH1 "$config{'python'} $config{'spades'} $config{'spades_Parameters'} -1 $path1 -2 $path2 -o $OOO/$name/ 1>$OOO/$name/spades_$name.sh.log 2>&1 && \\\n";
        print SH1 "$Bin/Shlib/cs.o $OOO/$name/scaffolds.fasta > $OOO/$name/scaffolds.fasta.stat && \\\n";
        print SH1 "$config{'perl'} $Bin/Shlib/took_longest.pl $OOO/$name/scaffolds.fasta $OOO/$name/scaffolds_longest.fasta && \\\n";
        print SH1 "echo ==========05.ASS end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/$name/spades_$name.sh.sign\n";
        close SH1;
        $data{$name} = "$OOO/$name/scaffolds.fasta";
        print NP "$name\t$OOO/$name/scaffolds.fasta\n";
        print NP2 "$name\t$OOO/$name/scaffolds_longest.fasta\n";
        print LG1 "$name\t$OOO/$name/scaffolds.fasta.stat\n";
        print SALL "sh $OOO/$name/spades_$name.sh\n";
        print SALL "sh $OOO/stat.sh\n";
    }
    close LG1;
    close NP;
    close NP2;
    my $Parse_cs = "$Bin/Shlib/Parse_cs.pl";
    open Stat, ">$OOO/stat.sh" or die $!;
    print Stat "$config{'perl'} $Parse_cs $OOO/log.np $OOO/all_ass_stat.xls\n";
    print Stat "echo ==========05.ASS_stat end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/stat.sh.sign\n";
    close Stat;
    close SALL;
}

################################### 06.Pilon consensus
if($config{'cns_method'} eq "pilon"){
    my $OOO = "$outpath/06.CNS"; 
    mkdir ($OOO) unless (-d $OOO);
    open SALL,">$shellall/06.CNS_dependence.txt" or die $!;
    push @dependent,"$shellall/06.CNS_dependence.txt";
    open NP,">$OOO/Odata.np" or die $!;
    open NP2,">$OOO/log.np" or die $!;
    foreach my $name (@sample){
        mkdir("$OOO/$name") unless (-d "$OOO/$name");
        my $ibam = $data{"$name.bam"};
        my $mem = $config{'cns_MEM'};
        open SH1,">$OOO/$name/cns_$name.sh" or die $!;
        print SH1 "$config{'java'} -Xmx$mem -jar $config{'pilon'} $config{'pilon_Parameters'} --bam $ibam --output $name.pilon --outdir $OOO/$name/ 1>$OOO/$name/$name.pilon.o 2>$OOO/$name/$name.pilon.e && \\\n";
        print SH1 "$config{'perl'} $Bin/Shlib/Parse_PilonVCF.pl $OOO/$name/$name.pilon.vcf $OOO/$name/$name.pilon.vcf $config{'pilon_Depth'} && \\\n";
        print SH1 "$config{'bedtools'} maskfasta -fi $OOO/$name/$name.pilon.fasta -bed $OOO/$name/$name.pilon.vcf.masked.bed -fo $OOO/$name/$name.masked.fasta && \\\n";
        print SH1 "$Bin/Shlib/cs.o $OOO/$name/$name.masked.fasta > $OOO/$name/$name.masked.fasta.stat && \\\n";
        print SH1 "echo ==========06.CNS end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/$name/cns_$name.sh.sign\n";
        close SH1;
        $data{"$name.cns"} = "$OOO/$name/$name.masked.fasta";
        print NP "$name $OOO/$name/$name.masked.fasta\n";
        print NP2 "$name $OOO/$name/$name.masked.fasta.stat\n";
        print SALL "sh $OOO/$name/cns_$name.sh\n";
        print SALL "sh $OOO/stat.sh\n";
    }
    close LG1;
    close NP;
    my $Parse_cs = "$Bin/Shlib/Parse_cs_CNS.pl";
    open Stat, ">$OOO/stat.sh" or die $!;
    print Stat "$config{'perl'} $Parse_cs $OOO/log.np $OOO/all_cns_stat.xls\n";
    print Stat "echo ==========06.CNS_stat end at : `date` ========== && \\\necho Still_waters_run_deep 1>&2 && \\\necho Still_waters_run_deep > $OOO/stat.sh.sign\n";
    close Stat;
    close SALL;
}

################################### all dependent
if(-s "$outpath/shellall/allDependent.sh"){`rm $outpath/shellall/allDependent.sh`;}
foreach(@dependent){
    `cat $_ >>$outpath/shellall/allDependent.sh`;
}

print strftime(">>>Generate shell scripts finished at:%Y-%m-%d,%H:%M:%S\n\n",localtime(time));
################################### sub
sub readConf{
    my $confFile = shift @_; 
    my %hash;
    open IN, $confFile or die "Cannot open file $confFile:$!\n";
    while (<IN>){
        chomp;
        next if(/^\s*$/ || /^\s*\#/);
        $_ =~ s/^\s*//;
        $_ =~ s/#(.)*//;
        $_ =~ s/\s*$//;
        if (/^(\w+)\s*=\s*(.*)$/xms){
            next if ($2 =~ /^\s*$/);
            my $key = $1; 
            my $value = $2; 
            $value =~ s/\s*$//;
            $hash{$key} = $value;
        }
    }   
    return %hash;
}

